// services/userService.js - MISE À JOUR avec support des rôles multiples
const User = require('../models/User');
const Role = require('../models/Role');
const bcrypt = require('bcryptjs');
const logger = require('../utils/logger');
const { rabbitmq } = require('../utils/rabbitmq');

module.exports = {
  /**
   * Get all users with populated roles (INCLUDING additionalRoles)
   */
  async getAllUsers(req) {
    try {
      console.log("🔍 Getting all users...");
      
      const users = await User.find()
        .populate('role', 'name permissions')
        .populate('additionalRoles', 'name permissions') // ✅ AJOUTÉ
        .select('-password -twoFactorCode -twoFactorExpires')
        .sort({ createdAt: -1 });

      console.log(`✅ Found ${users.length} users`);
      
      // ✅ AJOUTÉ: Ajouter les méthodes personnalisées aux users retournés
      const usersWithMethods = users.map(user => {
        const userObj = user.toObject();
        userObj.allPermissions = user.getAllPermissions();
        userObj.allRoleNames = user.getAllRoleNames();
        return userObj;
      });
      
      // Log the access
      await logger.auth("VIEW_USERS", req.user.id, `Viewed all users (${users.length} found)`, req);

      return usersWithMethods;
    } catch (error) {
      console.error("❌ Get all users error:", error);
      throw error;
    }
  },

  /**
   * Get user by ID with additionalRoles
   */
  async getUserById(userId, req) {
    try {
      console.log("🔍 Getting user by ID:", userId);
      
      const user = await User.findById(userId)
        .populate('role', 'name permissions')
        .populate('additionalRoles', 'name permissions') // ✅ AJOUTÉ
        .select('-password -twoFactorCode -twoFactorExpires');

      if (!user) {
        throw new Error('User not found');
      }

      console.log("✅ User found:", user.email);
      
      // ✅ AJOUTÉ: Ajouter les méthodes personnalisées
      const userObj = user.toObject();
      userObj.allPermissions = user.getAllPermissions();
      userObj.allRoleNames = user.getAllRoleNames();
      
      // Log the access
      await logger.auth("VIEW_USER", req.user.id, `Viewed user ${user.email}`, req, { targetUserId: userId });

      return userObj;
    } catch (error) {
      console.error("❌ Get user by ID error:", error);
      throw error;
    }
  },

  /**
   * Create new user - MISE À JOUR avec support multi-rôles
   */
  async createUser(userData, req) {
    try {
      console.log("🔄 Creating new user:", userData.email);
      
      const { 
        email, 
        password, 
        firstname, 
        lastname, 
        specialite, 
        role: roleId,
        additionalRoles, // ✅ AJOUTÉ
        active = true // ✅ AJOUTÉ
      } = userData;

      // Validate required fields
      if (!email || !password || !firstname || !lastname || !roleId) {
        throw new Error('Missing required fields: email, password, firstname, lastname, role');
      }

      // Check if email already exists
      const existingUser = await User.findOne({ email });
      if (existingUser) {
        throw new Error('Email already in use');
      }

      // Validate primary role
      const role = await Role.findById(roleId);
      if (!role) {
        throw new Error('Invalid role specified');
      }

      // ✅ AJOUTÉ: Validate additional roles if provided
      let validatedAdditionalRoles = [];
      if (additionalRoles && Array.isArray(additionalRoles) && additionalRoles.length > 0) {
        console.log("🔍 Validating additional roles:", additionalRoles);
        
        for (const additionalRoleId of additionalRoles) {
          const additionalRole = await Role.findById(additionalRoleId);
          if (!additionalRole) {
            throw new Error(`Invalid additional role specified: ${additionalRoleId}`);
          }
          // Don't duplicate the primary role
          if (additionalRoleId !== roleId) {
            validatedAdditionalRoles.push(additionalRoleId);
          }
        }
      }

      // Validate specialty for doctors
      if (role.name === 'Doctor' && !specialite) {
        throw new Error('Specialty is required for doctors');
      }

      // Create user
      const user = new User({
        email,
        password,
        firstname,
        lastname,
        specialite,
        role: roleId,
        additionalRoles: validatedAdditionalRoles, // ✅ AJOUTÉ
        emailVerified: true, // Auto-verify for admin-created users
        active
      });

      await user.save();
      console.log("✅ User created:", user._id);
      console.log("📋 Additional roles assigned:", validatedAdditionalRoles);

      // Get user with populated roles for response
      const populatedUser = await User.findById(user._id)
        .populate('role', 'name permissions')
        .populate('additionalRoles', 'name permissions') // ✅ AJOUTÉ
        .select('-password -twoFactorCode -twoFactorExpires');

      // ✅ AJOUTÉ: Ajouter les méthodes personnalisées
      const userObj = populatedUser.toObject();
      userObj.allPermissions = populatedUser.getAllPermissions();
      userObj.allRoleNames = populatedUser.getAllRoleNames();

      // Log the creation
      await logger.auth("CREATE_USER", req.user.id, `Created user ${email} with role ${role.name} + ${validatedAdditionalRoles.length} additional roles`, req, { 
        targetUserId: user._id,
        targetUserEmail: email,
        role: role.name,
        additionalRolesCount: validatedAdditionalRoles.length
      });

      // Notify other services
      try {
        await rabbitmq.sendMessage("user-events", {
          type: "user.created",
          userId: user._id.toString(),
          email: user.email,
          role: role.name,
          additionalRolesCount: validatedAdditionalRoles.length,
          createdBy: req.user.id,
          timestamp: new Date().toISOString()
        });
      } catch (mqError) {
        console.error("⚠️ Failed to send user creation event:", mqError.message);
      }

      return userObj;
    } catch (error) {
      console.error("❌ Create user error:", error);
      throw error;
    }
  },

  /**
   * Update user - MISE À JOUR avec support multi-rôles
   */
  async updateUser(userId, updateData, req) {
    try {
      console.log("🔄 Updating user:", userId);
      console.log("📝 Update data received:", updateData);
      
      const user = await User.findById(userId);
      if (!user) {
        throw new Error('User not found');
      }

      // ✅ MISE À JOUR: Gérer les rôles multiples
      let updatedFields = { ...updateData };

      // Validate primary role if being updated
      if (updateData.role) {
        const role = await Role.findById(updateData.role);
        if (!role) {
          throw new Error('Invalid role specified');
        }
        
        // Check specialty requirement for doctors
        if (role.name === 'Doctor' && !updateData.specialite && !user.specialite) {
          throw new Error('Specialty is required for doctors');
        }
      }

      // ✅ NOUVEAU: Gérer les rôles additionnels
      if (updateData.additionalRoles !== undefined) {
        console.log("🔍 Processing additional roles:", updateData.additionalRoles);
        
        if (Array.isArray(updateData.additionalRoles)) {
          // Validate all additional roles
          const validatedAdditionalRoles = [];
          
          for (const roleId of updateData.additionalRoles) {
            const role = await Role.findById(roleId);
            if (!role) {
              throw new Error(`Invalid additional role specified: ${roleId}`);
            }
            
            // Don't duplicate the primary role
            const primaryRoleId = updateData.role || user.role.toString();
            if (roleId !== primaryRoleId) {
              validatedAdditionalRoles.push(roleId);
            }
          }
          
          updatedFields.additionalRoles = validatedAdditionalRoles;
          console.log("✅ Validated additional roles:", validatedAdditionalRoles);
        } else {
          // If it's not an array, set to empty
          updatedFields.additionalRoles = [];
        }
      }

      // Handle password update if provided
      if (updateData.password) {
        updatedFields.password = await bcrypt.hash(updateData.password, 10);
      }

      console.log("📋 Final update fields:", Object.keys(updatedFields));

      // Update user
      const updatedUser = await User.findByIdAndUpdate(
        userId,
        { $set: updatedFields },
        { new: true, runValidators: true }
      )
      .populate('role', 'name permissions')
      .populate('additionalRoles', 'name permissions') // ✅ AJOUTÉ
      .select('-password -twoFactorCode -twoFactorExpires');

      console.log("✅ User updated:", updatedUser.email);
      console.log("📋 Updated roles:", {
        primary: updatedUser.role.name,
        additional: updatedUser.additionalRoles.map(r => r.name)
      });

      // ✅ AJOUTÉ: Ajouter les méthodes personnalisées
      const userObj = updatedUser.toObject();
      userObj.allPermissions = updatedUser.getAllPermissions();
      userObj.allRoleNames = updatedUser.getAllRoleNames();

      // Log the update
      await logger.auth("UPDATE_USER", req.user.id, `Updated user ${updatedUser.email}`, req, { 
        targetUserId: userId,
        updatedFields: Object.keys(updatedFields)
      });

      // Notify other services
      try {
        await rabbitmq.sendMessage("user-events", {
          type: "user.updated",
          userId: userId,
          email: updatedUser.email,
          updatedBy: req.user.id,
          updatedFields: Object.keys(updatedFields),
          timestamp: new Date().toISOString()
        });
      } catch (mqError) {
        console.error("⚠️ Failed to send user update event:", mqError.message);
      }

      return userObj;
    } catch (error) {
      console.error("❌ Update user error:", error);
      throw error;
    }
  },

  /**
   * Delete user - Updated to handle additional roles
   */
  async deleteUser(userId, req) {
    try {
      console.log("🗑️ Deleting user:", userId);
      
      const user = await User.findById(userId)
        .populate('role', 'name')
        .populate('additionalRoles', 'name'); // ✅ AJOUTÉ
        
      if (!user) {
        throw new Error('User not found');
      }

      // Prevent self-deletion
      if (userId === req.user.id) {
        throw new Error('Cannot delete your own account');
      }

      await User.findByIdAndDelete(userId);
      console.log("✅ User deleted:", user.email);

      // Log the deletion
      await logger.auth("DELETE_USER", req.user.id, `Deleted user ${user.email}`, req, { 
        targetUserId: userId,
        targetUserEmail: user.email,
        roleCount: 1 + (user.additionalRoles ? user.additionalRoles.length : 0)
      });

      // Notify other services
      try {
        await rabbitmq.sendMessage("user-events", {
          type: "user.deleted",
          userId: userId,
          email: user.email,
          deletedBy: req.user.id,
          timestamp: new Date().toISOString()
        });
      } catch (mqError) {
        console.error("⚠️ Failed to send user deletion event:", mqError.message);
      }

      return { message: 'User deleted successfully' };
    } catch (error) {
      console.error("❌ Delete user error:", error);
      throw error;
    }
  },

  /**
   * Toggle user status - Updated to populate additional roles
   */
  async toggleUserStatus(userId, req) {
    try {
      console.log("🔄 Toggling user status:", userId);
      
      const user = await User.findById(userId);
      if (!user) {
        throw new Error('User not found');
      }

      // Prevent self-deactivation
      if (userId === req.user.id) {
        throw new Error('Cannot change your own account status');
      }

      // Toggle status
      user.active = !user.active;
      await user.save();

      // Get updated user with populated roles
      const updatedUser = await User.findById(userId)
        .populate('role', 'name permissions')
        .populate('additionalRoles', 'name permissions') // ✅ AJOUTÉ
        .select('-password -twoFactorCode -twoFactorExpires');

      // ✅ AJOUTÉ: Ajouter les méthodes personnalisées
      const userObj = updatedUser.toObject();
      userObj.allPermissions = updatedUser.getAllPermissions();
      userObj.allRoleNames = updatedUser.getAllRoleNames();

      const action = user.active ? 'activated' : 'deactivated';
      console.log(`✅ User ${action}:`, user.email);

      // Log the status change
      await logger.auth("TOGGLE_USER_STATUS", req.user.id, `${action} user ${user.email}`, req, { 
        targetUserId: userId,
        newStatus: user.active ? 'active' : 'inactive'
      });

      // Notify other services
      try {
        await rabbitmq.sendMessage("user-events", {
          type: "user.status_changed",
          userId: userId,
          email: user.email,
          newStatus: user.active,
          changedBy: req.user.id,
          timestamp: new Date().toISOString()
        });
      } catch (mqError) {
        console.error("⚠️ Failed to send user status change event:", mqError.message);
      }

      return {
        message: `User ${action} successfully`,
        user: userObj
      };
    } catch (error) {
      console.error("❌ Toggle user status error:", error);
      throw error;
    }
  },

  /**
   * Get all roles for user creation/editing
   */
  async getAllRoles(req) {
    try {
      console.log("🔍 Getting all roles...");
      
      const roles = await Role.find().sort({ name: 1 });
      
      console.log(`✅ Found ${roles.length} roles`);
      
      // Log the access
      await logger.auth("VIEW_ROLES", req.user.id, `Viewed all roles`, req);

      return roles;
    } catch (error) {
      console.error("❌ Get all roles error:", error);
      throw error;
    }
  },


/**
 * Change user password (by admin)
 */
async changePassword(userId, passwordData, req) {
  try {
    console.log("🔄 Changing password for user:", userId);
    
    const { currentPassword, newPassword } = passwordData;
    
    // Get user with password for verification
    const user = await User.findById(userId).select('+password');
    if (!user) {
      throw new Error('User not found');
    }

    // Verify current password
    const isCurrentPasswordValid = await bcrypt.compare(currentPassword, user.password);
    if (!isCurrentPasswordValid) {
      throw new Error('Current password is incorrect');
    }

    // Check if new password is different from current
    const isSamePassword = await bcrypt.compare(newPassword, user.password);
    if (isSamePassword) {
      throw new Error('New password must be different from current password');
    }

    // Hash new password
    const hashedNewPassword = await bcrypt.hash(newPassword, 10);
    
    // Update password
    await User.findByIdAndUpdate(userId, {
      password: hashedNewPassword,
      passwordChangedAt: new Date()
    });

    console.log("✅ Password changed successfully for:", user.email);

    // Log the password change
    await logger.auth("CHANGE_PASSWORD", req.user.id, `Changed password for user ${user.email}`, req, { 
      targetUserId: userId,
      targetUserEmail: user.email
    });

    // Notify other services
    try {
      await rabbitmq.sendMessage("user-events", {
        type: "user.password_changed",
        userId: userId,
        email: user.email,
        changedBy: req.user.id,
        timestamp: new Date().toISOString()
      });
    } catch (mqError) {
      console.error("⚠️ Failed to send password change event:", mqError.message);
    }

    return { message: 'Password changed successfully' };
  } catch (error) {
    console.error("❌ Change password error:", error);
    throw error;
  }
},

/**
 * Change own password (by user themselves)
 */
async changeOwnPassword(passwordData, req) {
  try {
    console.log("🔄 User changing own password:", req.user.email);
    
    const { currentPassword, newPassword } = passwordData;
    const userId = req.user.id;
    
    // Get user with password for verification
    const user = await User.findById(userId).select('+password');
    if (!user) {
      throw new Error('User not found');
    }

    // Verify current password
    const isCurrentPasswordValid = await bcrypt.compare(currentPassword, user.password);
    if (!isCurrentPasswordValid) {
      throw new Error('Current password is incorrect');
    }

    // Check if new password is different from current
    const isSamePassword = await bcrypt.compare(newPassword, user.password);
    if (isSamePassword) {
      throw new Error('New password must be different from current password');
    }

    // Hash new password
    const hashedNewPassword = await bcrypt.hash(newPassword, 10);
    
    // Update password
    await User.findByIdAndUpdate(userId, {
      password: hashedNewPassword,
      passwordChangedAt: new Date()
    });

    console.log("✅ User successfully changed own password:", user.email);

    // Log the password change
    await logger.auth("CHANGE_OWN_PASSWORD", userId, `Changed own password`, req);

    // Notify other services
    try {
      await rabbitmq.sendMessage("user-events", {
        type: "user.own_password_changed",
        userId: userId,
        email: user.email,
        timestamp: new Date().toISOString()
      });
    } catch (mqError) {
      console.error("⚠️ Failed to send password change event:", mqError.message);
    }

    return { message: 'Password changed successfully' };
  } catch (error) {
    console.error("❌ Change own password error:", error);
    throw error;
  }
},
  /**
   * Search users by query - Updated to include additional roles
   */
  async searchUsers(query, req) {
    try {
      console.log("🔍 Searching users with query:", query);
      
      const searchRegex = new RegExp(query, 'i');
      
      const users = await User.find({
        $or: [
          { firstname: searchRegex },
          { lastname: searchRegex },
          { email: searchRegex },
          { specialite: searchRegex }
        ]
      })
      .populate('role', 'name permissions')
      .populate('additionalRoles', 'name permissions') // ✅ AJOUTÉ
      .select('-password -twoFactorCode -twoFactorExpires')
      .sort({ createdAt: -1 });

      // ✅ AJOUTÉ: Ajouter les méthodes personnalisées
      const usersWithMethods = users.map(user => {
        const userObj = user.toObject();
        userObj.allPermissions = user.getAllPermissions();
        userObj.allRoleNames = user.getAllRoleNames();
        return userObj;
      });

      console.log(`✅ Found ${users.length} users matching query`);
      
      // Log the search
      await logger.auth("SEARCH_USERS", req.user.id, `Searched users with query: ${query}`, req, { 
        query,
        resultsCount: users.length
      });

      return usersWithMethods;
    } catch (error) {
      console.error("❌ Search users error:", error);
      throw error;
    }
  }
};