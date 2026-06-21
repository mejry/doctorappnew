// services/roleService.js - Version simplifiée avec double référence
const Role = require('../models/Role');
const User = require('../models/User');
const logger = require('../utils/logger');
const { rabbitMQ } = require('../utils/rabbitmq');

module.exports = {
  /**
   * Create a new role avec assignation d'utilisateurs
   */
  async createRole(name, permissions, admin, req, userIds = []) {
    if (!name || !permissions || !permissions.length) {
      throw new Error('Name and permissions required');
    }
    
    const existingRole = await Role.findOne({ name });
    if (existingRole) {
      throw new Error(`Role "${name}" already exists`);
    }
    
    // ✅ Créer le rôle avec les utilisateurs assignés
    const role = await Role.create({ 
      name, 
      permissions,
      assignedUsers: userIds || []
    });
    
    // ✅ Ajouter ce rôle aux utilisateurs (comme rôle additionnel)
    const assignedUsers = [];
    if (userIds && userIds.length > 0) {
      for (const userId of userIds) {
        try {
          const user = await User.findById(userId);
          if (user) {
            // Ajouter comme rôle additionnel s'il n'existe pas déjà
            if (!user.additionalRoles.includes(role._id)) {
              user.additionalRoles.push(role._id);
              await user.save();
            }
            
            assignedUsers.push({
              _id: user._id,
              name: `${user.firstname} ${user.lastname}`,
              email: user.email
            });
          }
        } catch (error) {
          console.error(`Failed to assign user ${userId} to role:`, error);
        }
      }
    }
    
    await logger.role('ROLE_CREATED', admin, name, `Role "${name}" created with ${assignedUsers.length} users assigned`, req);
    
    try {
      await rabbitMQ.sendMessage('user-service-updates', {
        type: 'role.created',
        data: {
          roleId: role._id,
          name: role.name,
          permissions: role.permissions,
          assignedUsersCount: assignedUsers.length
        }
      });
    } catch (mqError) {
      console.error('Failed to notify other services about role creation:', mqError);
    }
    
    return {
      ...role.toJSON(),
      assignedUsersDetails: assignedUsers
    };
  },

  /**
   * Get all roles avec leurs utilisateurs assignés
   */
  async getRoles() {
    const roles = await Role.find()
      .populate('assignedUsers', '_id firstname lastname email')
      .sort('name');
    
    return roles.map(role => ({
      ...role.toJSON(),
      assignedUsersDetails: role.assignedUsers.map(user => ({
        _id: user._id,
        name: `${user.firstname} ${user.lastname}`,
        email: user.email
      }))
    }));
  },

  /**
   * Get role by ID avec utilisateurs
   */
  async getRoleById(roleId) {
    const role = await Role.findById(roleId)
      .populate('assignedUsers', '_id firstname lastname email');
    
    if (!role) {
      throw new Error('Role not found');
    }
    
    return {
      ...role.toJSON(),
      assignedUsersDetails: role.assignedUsers.map(user => ({
        _id: user._id,
        name: `${user.firstname} ${user.lastname}`,
        email: user.email
      }))
    };
  },

  /**
   * Update a role avec gestion des utilisateurs
   */
  async updateRole(roleId, updates, admin, req) {
    const role = await Role.findById(roleId);
    if (!role) { 
      throw new Error('Role not found');
    }
    
    if (role.name === 'Admin' && updates.name !== 'Admin') {
      throw new Error('Cannot rename Admin role');
    }
    
    const changes = [];
    
    // Mise à jour du nom
    if (updates.name && updates.name !== role.name) {
      changes.push(`Name changed from "${role.name}" to "${updates.name}"`);
      role.name = updates.name;
    }
    
    // Mise à jour des permissions
    if (updates.permissions) {
      const addedPermissions = updates.permissions.filter(p => !role.permissions.includes(p));
      const removedPermissions = role.permissions.filter(p => !updates.permissions.includes(p));
      
      if (addedPermissions.length) {
        changes.push(`Added permissions: ${addedPermissions.join(', ')}`);
      }
      
      if (removedPermissions.length) {
        changes.push(`Removed permissions: ${removedPermissions.join(', ')}`);
      }
      
      role.permissions = updates.permissions;
    }

    // ✅ Gestion des utilisateurs assignés
    if (updates.userIds && Array.isArray(updates.userIds)) {
      // Retirer ce rôle des anciens utilisateurs
      await User.updateMany(
        { additionalRoles: roleId },
        { $pull: { additionalRoles: roleId } }
      );
      
      // Mettre à jour la liste dans le rôle
      role.assignedUsers = updates.userIds;
      
      // Ajouter le rôle aux nouveaux utilisateurs
      for (const userId of updates.userIds) {
        try {
          await User.findByIdAndUpdate(
            userId,
            { $addToSet: { additionalRoles: roleId } }
          );
        } catch (error) {
          console.error(`Failed to assign user ${userId} to role:`, error);
        }
      }
      
      changes.push(`Users assigned: ${updates.userIds.length}`);
    }
    
    if (changes.length > 0) {
      await role.save();
      
      await logger.role('ROLE_UPDATED', admin, role.name, `Role "${role.name}" updated: ${changes.join('; ')}`, req);
      
      try {
        await rabbitMQ.sendMessage('user-service-updates', {
          type: 'role.updated',
          data: {
            roleId: role._id,
            name: role.name,
            permissions: role.permissions
          }
        });
      } catch (mqError) {
        console.error('Failed to notify other services about role update:', mqError);
      }
    }

    // Récupérer le rôle mis à jour avec les utilisateurs
    const updatedRole = await Role.findById(roleId)
      .populate('assignedUsers', '_id firstname lastname email');

    return {
      ...updatedRole.toJSON(),
      assignedUsersDetails: updatedRole.assignedUsers.map(user => ({
        _id: user._id,
        name: `${user.firstname} ${user.lastname}`,
        email: user.email
      }))
    };
  },

  /**
   * Assign role to user (ajouter un rôle additionnel)
   */
  async assignRole(userId, roleId, admin, req) {
    const user = await User.findById(userId);
    if (!user) {
      throw new Error('User not found');
    }
    
    const role = await Role.findById(roleId);
    if (!role) {
      throw new Error('Role not found');
    }
    
    // ✅ Ajouter le rôle à l'utilisateur s'il n'existe pas déjà
    if (!user.additionalRoles.includes(roleId)) {
      user.additionalRoles.push(roleId);
      await user.save();
    }
    
    // ✅ Ajouter l'utilisateur au rôle s'il n'existe pas déjà
    if (!role.assignedUsers.includes(userId)) {
      role.assignedUsers.push(userId);
      await role.save();
    }
    
    await logger.user(
      'ROLE_ASSIGNED', 
      admin, 
      user, 
      `Role "${role.name}" added to user ${user.email}`,
      req
    );
    
    try {
      await rabbitMQ.sendMessage('user-service-updates', {
        type: 'user.role_added',
        data: {
          userId: user._id,
          roleId: role._id,
          roleName: role.name
        }
      });
    } catch (mqError) {
      console.error('Failed to notify other services about role assignment:', mqError);
    }
    
    // Retourner l'utilisateur avec tous ses rôles
    const updatedUser = await User.findById(userId)
      .populate('role', 'name permissions')
      .populate('additionalRoles', 'name permissions')
      .select('-password -twoFactorCode -twoFactorExpires');
    
    return updatedUser.toJSON();
  },

  /**
   * Remove role from user
   */
  async removeRoleFromUser(userId, roleId, admin, req) {
    const user = await User.findById(userId);
    if (!user) {
      throw new Error('User not found');
    }
    
    const role = await Role.findById(roleId);
    if (!role) {
      throw new Error('Role not found');
    }
    
    // ✅ Retirer le rôle de l'utilisateur
    user.additionalRoles = user.additionalRoles.filter(r => r.toString() !== roleId.toString());
    await user.save();
    
    // ✅ Retirer l'utilisateur du rôle
    role.assignedUsers = role.assignedUsers.filter(u => u.toString() !== userId.toString());
    await role.save();
    
    await logger.user(
      'ROLE_REMOVED', 
      admin, 
      user, 
      `Role "${role.name}" removed from user ${user.email}`,
      req
    );
    
    const updatedUser = await User.findById(userId)
      .populate('role', 'name permissions')
      .populate('additionalRoles', 'name permissions')
      .select('-password -twoFactorCode -twoFactorExpires');
    
    return updatedUser.toJSON();
  },

  // Autres méthodes restent identiques...
  async deleteRole(roleId, admin, req) {
    const role = await Role.findById(roleId);
    if (!role) {
      throw new Error('Role not found');
    }
    
    if (['Admin', 'Doctor', 'Secretary', 'User'].includes(role.name)) {
      throw new Error(`Cannot delete default role: ${role.name}`);
    }
    
    // Vérifier si le rôle est assigné
    const usersWithRole = await User.countDocuments({ 
      additionalRoles: roleId 
    });
    
    if (usersWithRole > 0) {
      throw new Error(`Cannot delete role "${role.name}" as it is assigned to ${usersWithRole} user(s)`);
    }
    
    await role.deleteOne();
    
    await logger.role('ROLE_DELETED', admin, role.name, `Role "${role.name}" deleted`, req);
    
    return true;
  },

  async getAllPermissions() {
    const roles = await Role.find({}, 'permissions');
    const allPermissions = new Set();
    
    roles.forEach(role => {
      if (role.permissions && role.permissions.length > 0) {
        role.permissions.forEach(permission => {
          allPermissions.add(permission);
        });
      }
    });
    
    return Array.from(allPermissions).sort();
  },

  async addPermission(roleId, permission, admin, req) {
    const role = await Role.findById(roleId);
    if (!role) {
      throw new Error('Role not found');
    }
    
    if (role.permissions.includes(permission)) {
      throw new Error(`Permission "${permission}" already exists in this role`);
    }
    
    role.permissions.push(permission);
    await role.save();
    
    await logger.role(
      'PERMISSION_ADDED', 
      admin, 
      role.name, 
      `Permission "${permission}" added to role "${role.name}"`, 
      req
    );
    
    return role;
  },

  async removePermission(roleId, permission, admin, req) {
    const role = await Role.findById(roleId);
    if (!role) {
      throw new Error('Role not found');
    }
    
    if (!role.permissions.includes(permission)) {
      throw new Error(`Permission "${permission}" does not exist in this role`);
    }
    
    role.permissions = role.permissions.filter(p => p !== permission);
    await role.save();
    
    await logger.role(
      'PERMISSION_REMOVED', 
      admin, 
      role.name, 
      `Permission "${permission}" removed from role "${role.name}"`, 
      req
    );
    
    return role;
  }
};