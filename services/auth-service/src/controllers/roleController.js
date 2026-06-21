// controllers/roleController.js - Version simplifiée pour vos besoins
const roleService = require('../services/roleService');
const User = require('../models/User');

module.exports = {
  /**
   * Get all roles
   */
  async getRoles(req, res) {
    try {
      const roles = await roleService.getRoles();
      res.json(roles);
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  },
  
  /**
   * Get role by ID
   */
  async getRoleById(req, res) {
    try {
      const { roleId } = req.params;
      const role = await roleService.getRoleById(roleId);
      res.json(role);
    } catch (err) {
      res.status(404).json({ error: err.message });
    }
  },
  
  /**
   * Create a new role avec utilisateurs
   */
  async createRole(req, res) {
    try {
      const { name, permissions, users } = req.body;
      
      if (!name || !Array.isArray(permissions)) {
        return res.status(400).json({ error: 'Name and permissions array required' });
      }

      console.log('Creating role:', { name, permissions, users });
      
      // ✅ Extraire les IDs des utilisateurs depuis le body
      const userIds = users && Array.isArray(users) 
        ? users.map(user => typeof user === 'string' ? user : user._id || user.id)
        : [];

      const role = await roleService.createRole(
        name, 
        permissions, 
        req.user.id, 
        req, 
        userIds
      );
      
      console.log('Role created successfully:', role.name);
      res.status(201).json(role);
    } catch (err) {
      console.error('Create role error:', err);
      res.status(400).json({ error: err.message });
    }
  },
  
  /**
   * Update a role
   */
  async updateRole(req, res) {
    try {
      const { roleId } = req.params;
      const updates = req.body;
      
      console.log('Updating role:', roleId, updates);

      // ✅ Si des utilisateurs sont fournis, extraire leurs IDs
      if (updates.users && Array.isArray(updates.users)) {
        updates.userIds = updates.users.map(user => 
          typeof user === 'string' ? user : user._id || user.id
        );
      }
      
      const role = await roleService.updateRole(roleId, updates, req.user.id, req);
      
      console.log('Role updated successfully:', role.name);
      res.json(role);
    } catch (err) {
      console.error('Update role error:', err);
      res.status(400).json({ error: err.message });
    }
  },
  
  /**
   * Delete a role
   */
  async deleteRole(req, res) {
    try {
      const { roleId } = req.params;
      
      await roleService.deleteRole(roleId, req.user.id, req);
      
      res.json({ message: 'Role deleted successfully' });
    } catch (err) {
      console.error('Delete role error:', err);
      res.status(400).json({ error: err.message });
    }
  },
  
  /**
   * Assign role to user (ajouter un rôle additionnel)
   */
  async assignRole(req, res) {
    try {
      const { userId, roleId } = req.body;
      
      if (!userId || !roleId) {
        return res.status(400).json({ error: 'User ID and role ID required' });
      }
      
      console.log('Assigning additional role:', { userId, roleId });
      
      const user = await roleService.assignRole(userId, roleId, req.user.id, req);
      
      console.log('Additional role assigned successfully to user:', user.email);
      res.json({ message: 'Additional role assigned successfully', user });
    } catch (err) {
      console.error('Assign role error:', err);
      res.status(400).json({ error: err.message });
    }
  },

  /**
   * Get users assigned to a specific role
   */
  async getUsersByRole(req, res) {
    try {
      const { roleId } = req.params;

      const role = await roleService.getRoleById(roleId);
      if (!role) {
        return res.status(404).json({ error: 'Role not found' });
      }

      res.json({
        role: role.name,
        users: role.assignedUsersDetails,
        count: role.assignedUsersDetails.length
      });
    } catch (err) {
      console.error('Get users by role error:', err);
      res.status(500).json({ error: err.message });
    }
  },
  
  /**
   * Get all unique permissions from all roles
   */
  async getAllPermissions(req, res) {
    try {
      const permissions = await roleService.getAllPermissions();
      res.json(permissions);
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  },
  
  /**
   * Get all users (pour l'interface d'assignation de rôles)
   */
  async getUsers(req, res) {
    try {
      const users = await User.find()
        .select('-password -twoFactorCode -twoFactorExpires')
        .populate('role', 'name permissions')
        .populate('additionalRoles', 'name permissions')
        .sort('firstname lastname email');

      console.log(`Users loaded successfully: ${users.length} users`);
      res.json(users);
    } catch (err) {
      console.error('Get users error:', err);
      res.status(500).json({ error: err.message });
    }
  },

  /**
   * Remove role from user
   */
  async removeRoleFromUser(req, res) {
    try {
      const { userId, roleId } = req.body;
      
      if (!userId || !roleId) {
        return res.status(400).json({ error: 'User ID and role ID required' });
      }
      
      console.log('Removing role from user:', { userId, roleId });
      
      const user = await roleService.removeRoleFromUser(userId, roleId, req.user.id, req);
      
      console.log('Role removed successfully from user:', user.email);
      res.json({ message: 'Role removed successfully', user });
    } catch (err) {
      console.error('Remove role from user error:', err);
      res.status(400).json({ error: err.message });
    }
  },

  /**
   * Get users with detailed role information
   */
  async getUsersWithRoles(req, res) {
    try {
      const users = await User.find()
        .select('-password -twoFactorCode -twoFactorExpires')
        .populate('role', 'name permissions')
        .populate('additionalRoles', 'name permissions')
        .sort('firstname lastname email');

      const usersWithDetails = users.map(user => {
        return {
          ...user.toJSON(),
          allPermissions: user.getAllPermissions(),
          allRoleNames: user.getAllRoleNames()
        };
      });

      console.log(`Users with roles loaded successfully: ${usersWithDetails.length} users`);
      res.json(usersWithDetails);
    } catch (err) {
      console.error('Get users with roles error:', err);
      res.status(500).json({ error: err.message });
    }
  },
  
  /**
   * Add a permission to a role
   */
  async addPermission(req, res) {
    try {
      const { roleId } = req.params;
      const { permission } = req.body;
      
      if (!permission) {
        return res.status(400).json({ error: 'Permission name is required' });
      }
      
      const role = await roleService.addPermission(
        roleId,
        permission,
        req.user.id,
        req
      );
      
      res.json(role);
    } catch (err) {
      res.status(400).json({ error: err.message });
    }
  },
  
  /**
   * Remove a permission from a role
   */
  async removePermission(req, res) {
    try {
      const { roleId, permission } = req.params;
      
      const role = await roleService.removePermission(
        roleId,
        permission,
        req.user.id,
        req
      );
      
      res.json(role);
    } catch (err) {
      res.status(400).json({ error: err.message });
    }
  },

  /**
   * Bulk assign users to a role
   */
  async bulkAssignRole(req, res) {
    try {
      const { userIds, roleId } = req.body;
      
      if (!Array.isArray(userIds) || !roleId) {
        return res.status(400).json({ error: 'User IDs array and role ID required' });
      }

      console.log('Bulk assigning role:', { userIds, roleId });

      const results = [];
      const errors = [];

      for (const userId of userIds) {
        try {
          const user = await roleService.assignRole(userId, roleId, req.user.id, req);
          results.push({
            userId,
            success: true,
            user: user
          });
        } catch (error) {
          console.error(`Failed to assign role to user ${userId}:`, error);
          errors.push({
            userId,
            success: false,
            error: error.message
          });
        }
      }

      res.json({
        message: `Processed ${userIds.length} assignments`,
        successful: results.length,
        failed: errors.length,
        results: results,
        errors: errors.length > 0 ? errors : undefined
      });
    } catch (err) {
      console.error('Bulk assign role error:', err);
      res.status(500).json({ error: err.message });
    }
  }
};