const userService = require('../services/userService');

module.exports = {
  /**
   * Get all users - CORRIGÉ avec vérification
   */
  async getAllUsers(req, res) {
    try {
      console.log('📋 Getting all users - Controller');
      console.log('User making request:', req.user?.email);
      
      // Double vérification de l'authentification
      if (!req.user) {
        console.log('❌ No authenticated user in controller');
        return res.status(401).json({ error: 'Authentication required' });
      }
      
      const users = await userService.getAllUsers(req);
      console.log(`✅ Returning ${users.length} users`);
      res.status(200).json(users);
    } catch (error) {
      console.error("❌ Get all users controller error:", error);
      res.status(500).json({ 
        error: error.message || 'Failed to retrieve users' 
      });
    }
  },

  /**
   * Get user by ID
   */
  async getUserById(req, res) {
    try {
      const { id } = req.params;
      
      if (!req.user) {
        return res.status(401).json({ error: 'Authentication required' });
      }
      
      const user = await userService.getUserById(id, req);
      res.status(200).json(user);
    } catch (error) {
      console.error("❌ Get user by ID controller error:", error);
      const statusCode = error.message === 'User not found' ? 404 : 500;
      res.status(statusCode).json({ 
        error: error.message || 'Failed to retrieve user' 
      });
    }
  },

  /**
   * Create new user
   */
  async createUser(req, res) {
    try {
      if (!req.user) {
        return res.status(401).json({ error: 'Authentication required' });
      }
      
      const user = await userService.createUser(req.body, req);
      res.status(201).json(user);
    } catch (error) {
      console.error("❌ Create user controller error:", error);
      res.status(400).json({ 
        error: error.message || 'Failed to create user' 
      });
    }
  },

  /**
   * Update user
   */
  async updateUser(req, res) {
    try {
      const { id } = req.params;
      
      if (!req.user) {
        return res.status(401).json({ error: 'Authentication required' });
      }
      
      const user = await userService.updateUser(id, req.body, req);
      res.status(200).json(user);
    } catch (error) {
      console.error("❌ Update user controller error:", error);
      const statusCode = error.message === 'User not found' ? 404 : 400;
      res.status(statusCode).json({ 
        error: error.message || 'Failed to update user' 
      });
    }
  },

  /**
   * Delete user
   */
  async deleteUser(req, res) {
    try {
      const { id } = req.params;
      
      if (!req.user) {
        return res.status(401).json({ error: 'Authentication required' });
      }
      
      const result = await userService.deleteUser(id, req);
      res.status(200).json(result);
    } catch (error) {
      console.error("❌ Delete user controller error:", error);
      const statusCode = error.message === 'User not found' ? 404 : 400;
      res.status(statusCode).json({ 
        error: error.message || 'Failed to delete user' 
      });
    }
  },

  /**
   * Toggle user status
   */
  async toggleUserStatus(req, res) {
    try {
      const { id } = req.params;
      
      if (!req.user) {
        return res.status(401).json({ error: 'Authentication required' });
      }
      
      const result = await userService.toggleUserStatus(id, req);
      res.status(200).json(result);
    } catch (error) {
      console.error("❌ Toggle user status controller error:", error);
      const statusCode = error.message === 'User not found' ? 404 : 400;
      res.status(statusCode).json({ 
        error: error.message || 'Failed to change user status' 
      });
    }
  },

  /**
   * Get all roles
   */
  async getAllRoles(req, res) {
    try {
      if (!req.user) {
        return res.status(401).json({ error: 'Authentication required' });
      }
      
      const roles = await userService.getAllRoles(req);
      res.status(200).json(roles);
    } catch (error) {
      console.error("❌ Get all roles controller error:", error);
      res.status(500).json({ 
        error: error.message || 'Failed to retrieve roles' 
      });
    }
  },
/**
 * Change user password (by admin)
 */
async changePassword(req, res) {
  try {
    const { id } = req.params;
    
    if (!req.user) {
      return res.status(401).json({ error: 'Authentication required' });
    }
    
    const result = await userService.changePassword(id, req.body, req);
    res.status(200).json(result);
  } catch (error) {
    console.error("❌ Change password controller error:", error);
    const statusCode = error.message === 'User not found' ? 404 : 400;
    res.status(statusCode).json({ 
      error: error.message || 'Failed to change password' 
    });
  }
},

/**
 * Change own password
 */
async changeOwnPassword(req, res) {
  try {
    if (!req.user) {
      return res.status(401).json({ error: 'Authentication required' });
    }
    
    const result = await userService.changeOwnPassword(req.body, req);
    res.status(200).json(result);
  } catch (error) {
    console.error("❌ Change own password controller error:", error);
    res.status(400).json({ 
      error: error.message || 'Failed to change password' 
    });
  }
},




  /**
   * Search users
   */



  async searchUsers(req, res) {
    try {
      const { q } = req.query;
      
      if (!req.user) {
        return res.status(401).json({ error: 'Authentication required' });
      }
      
      if (!q || q.trim().length < 2) {
        return res.status(400).json({ 
          error: 'Search query must be at least 2 characters long' 
        });
      }

      const users = await userService.searchUsers(q.trim(), req);
      res.status(200).json(users);
    } catch (error) {
      console.error("❌ Search users controller error:", error);
      res.status(500).json({ 
        error: error.message || 'Failed to search users' 
      });
    }
  }
};
