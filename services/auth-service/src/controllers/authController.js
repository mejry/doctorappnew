// controllers/authController.js
const authService = require('../services/authService');

module.exports = {
  /**
   * User login
   * @param {Object} req - Express request
   * @param {Object} res - Express response
   */
  async login(req, res) {
    try {
      const { email, password } = req.body;
      
      const data = await authService.login(email, password, req);
      
      // Set HTTP-only cookie with access token
      res.cookie('access_token', data.accessToken, {
        httpOnly: true,
        secure: process.env.NODE_ENV === 'production',
        sameSite: 'strict',
        maxAge: 900000 // 15 minutes
      });
      
      // Set HTTP-only cookie with refresh token
      if (data.refreshToken) {
        res.cookie('refresh_token', data.refreshToken, {
          httpOnly: true,
          secure: process.env.NODE_ENV === 'production',
          sameSite: 'strict',
          maxAge: 604800000 // 7 days
        });
      }
      
      res.status(200).json(data);
    } catch (err) {
      res.status(401).json({ error: err.message });
    }
  },
  
  /**
   * User registration
   * @param {Object} req - Express request
   * @param {Object} res - Express response
   */
  async register(req, res) {
    try {
      const user = await authService.register(req.body, req);
      res.status(201).json(user);
    } catch (err) {
      res.status(400).json({ error: err.message });
    }
  },
  
  /**
   * Refresh access token
   * @param {Object} req - Express request
   * @param {Object} res - Express response
   */
  async refreshToken(req, res) {
    try {
      // Get refresh token from cookie or request body
      const refreshToken = req.cookies.refresh_token || req.body.refreshToken;
      
      if (!refreshToken) {
        return res.status(401).json({ error: 'Refresh token required' });
      }
      
      const data = await authService.refreshToken(refreshToken);
      
      // Set HTTP-only cookie with new access token
      res.cookie('access_token', data.accessToken, {
        httpOnly: true,
        secure: process.env.NODE_ENV === 'production',
        sameSite: 'strict',
        maxAge: 900000 // 15 minutes
      });
      
      res.status(200).json(data);
    } catch (err) {
      // Clear cookies on error
      res.clearCookie('access_token');
      res.clearCookie('refresh_token');
      res.status(401).json({ error: err.message });
    }
  },
  /**
   * Send 2FA code
   * @param {Object} req - Express request
   * @param {Object} res - Express response
   */
  async send2FACode(req, res) {
    try {
      const { email } = req.body;
      
      if (!email) {
        return res.status(400).json({ error: 'Email required' });
      }
      
      await authService.send2FACode(email, req);
      
      res.json({ message: '2FA code sent' });
    } catch (err) {
      res.status(400).json({ error: err.message });
    }
  },
  
  /**
   * Verify 2FA code
   * @param {Object} req - Express request
   * @param {Object} res - Express response
   */
  async verify2FA(req, res) {
    try {
      const { userId, code } = req.body;
      
      if (!userId || !code) {
        return res.status(400).json({ error: 'User ID and code required' });
      }
      
      const data = await authService.verify2FA(userId, code, req);
      
      // Set HTTP-only cookie with access token
      res.cookie('access_token', data.accessToken, {
        httpOnly: true,
        secure: process.env.NODE_ENV === 'production',
        sameSite: 'strict',
        maxAge: 900000 // 15 minutes
      });
      
      // Set HTTP-only cookie with refresh token
      if (data.refreshToken) {
        res.cookie('refresh_token', data.refreshToken, {
          httpOnly: true,
          secure: process.env.NODE_ENV === 'production',
          sameSite: 'strict',
          maxAge: 604800000 // 7 days
        });
      }
      
      res.status(200).json(data);
    } catch (err) {
      res.status(401).json({ error: err.message });
    }
  },
  
  /**
   * Toggle 2FA for a user
   * @param {Object} req - Express request
   * @param {Object} res - Express response
   */
  async toggle2FA(req, res) {
    try {
      const { enable } = req.body;
      
      if (typeof enable !== 'boolean') {
        return res.status(400).json({ error: 'Enable parameter must be a boolean' });
      }
      
      const user = await authService.toggle2FA(req.user.id, enable, req);
      
      res.json({ message: `2FA ${enable ? 'enabled' : 'disabled'}`, user });
    } catch (err) {
      res.status(400).json({ error: err.message });
    }
  },
  
  /**
   * User logout
   * @param {Object} req - Express request
   * @param {Object} res - Express response
   */
  async logout(req, res) {
    try {
      // Clear cookies
      res.clearCookie('access_token');
      res.clearCookie('refresh_token');
      
      if (req.user && req.user.id) {
        await authService.logout(req.user.id, req);
      }
      
      res.json({ message: 'Logout successful' });
    } catch (err) {
      res.status(500).json({ error: 'Logout failed' });
    }
  },
  
  /**
   * Create a new role
   * @param {Object} req - Express request
   * @param {Object} res - Express response
   */
  async createRole(req, res) {
    try {
      const { name, permissions } = req.body;
      
      if (!name || !Array.isArray(permissions)) {
        return res.status(400).json({ error: 'Name and permissions array required' });
      }
      
      const roleService = require('../services/roleService');
      
      const role = await roleService.createRole(name, permissions, req.user.id, req);
      
      res.status(201).json(role);
    } catch (err) {
      res.status(400).json({ error: err.message });
    }
  },
  
  
  async getServiceToken(req, res) {
    try {
      const { serviceId, secret } = req.body;
      
      
      if (serviceId !== process.env.SERVICE_ID || secret !== process.env.SERVICE_SECRET) {
        return res.status(401).json({ error: 'Invalid service credentials' });
      }
      
      const jwtUtil = require('../utils/jwt');
      
      const serviceToken = jwtUtil.generateServiceToken({
        serviceId,
        service: 'service-to-service',
        issuedAt: new Date().toISOString()
      });
      
      res.json({ serviceToken });
    } catch (err) {
      res.status(500).json({ error: 'Failed to generate service token' });
    }
  },
   /**
   * Forget password - Generate and send new password
   * @param {Object} req - Express request
   * @param {Object} res - Express response
   */
   async forgetPassword(req, res) {
    try {
      const { email } = req.body;
      
      if (!email) {
        return res.status(400).json({ 
          success: false,
          error: 'Email is required' 
        });
      }

      // Validate email format
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      if (!emailRegex.test(email)) {
        return res.status(400).json({ 
          success: false,
          error: 'Invalid email format' 
        });
      }
      
      const result = await authService.forgetPassword(email, req);
      
      res.status(200).json(result);
    } catch (err) {
      console.error("Forget password controller error:", err);
      res.status(500).json({ 
        success: false,
        error: err.message || 'Unable to process request' 
      });
    }
  },
   /**
   * Change password for logged-in user
   * @param {Object} req - Express request
   * @param {Object} res - Express response
   */
   async changePassword(req, res) {
    try {
      const { currentPassword, newPassword, confirmPassword } = req.body;
      
      // Validation
      if (!currentPassword || !newPassword || !confirmPassword) {
        return res.status(400).json({ 
          success: false,
          error: 'Current password, new password, and confirm password are required' 
        });
      }

      if (newPassword !== confirmPassword) {
        return res.status(400).json({ 
          success: false,
          error: 'New password and confirm password do not match' 
        });
      }

      if (newPassword.length < 6) {
        return res.status(400).json({ 
          success: false,
          error: 'New password must be at least 6 characters long' 
        });
      }

      if (currentPassword === newPassword) {
        return res.status(400).json({ 
          success: false,
          error: 'New password must be different from current password' 
        });
      }

      // Get user ID from token (set by auth middleware)
      const userId = req.user.id;
      
      if (!userId) {
        return res.status(401).json({ 
          success: false,
          error: 'Authentication required' 
        });
      }
      
      const result = await authService.changePassword(userId, currentPassword, newPassword, req);
      
      // Clear cookies after password change for security
      res.clearCookie('access_token');
      res.clearCookie('refresh_token');
      
      res.status(200).json(result);
    } catch (err) {
      console.error("Change password controller error:", err);
      res.status(400).json({ 
        success: false,
        error: err.message || 'Unable to change password' 
      });
    }
  },
};