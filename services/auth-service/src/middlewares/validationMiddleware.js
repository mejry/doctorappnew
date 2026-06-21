// middlewares/validationMiddleware.js - FIXED
const validator = require('validator');
const Role = require('../models/Role'); // Add this import

module.exports = {
  /**
   * Validate user registration - FIXED: Dynamic role validation
   */
  validateRegister: async (req, res, next) => {
    const { email, password, firstname, lastname, role } = req.body;
    const errors = [];
    
    // Check required fields
    if (!email) errors.push('Email is required');
    if (!password) errors.push('Password is required');
    if (!firstname) errors.push('First name is required');
    if (!lastname) errors.push('Last name is required');
    if (!role) errors.push('Role is required');
    
    // Check email format
    if (email && !validator.isEmail(email)) {
      errors.push('Invalid email format');
    }
    
    // Check password strength
    if (password && password.length < 6) {
      errors.push('Password must be at least 6 characters');
    }
    
    // ✅ FIXED: Dynamic role validation - check against actual database roles
    if (role) {
      try {
        const validRole = await Role.findOne({ name: role });
        if (!validRole) {
          // Get all available roles from database
          const availableRoles = await Role.find({}, 'name');
          const roleNames = availableRoles.map(r => r.name).filter(name => name); // Filter out corrupted entries
          errors.push(`Invalid role: ${role}. Available roles: ${roleNames.join(', ')}`);
        }
      } catch (dbError) {
        console.error('Error validating role:', dbError);
        errors.push('Error validating role');
      }
    }
    
    // Check if specialty is provided for doctors
    if (role === 'Doctor' && !req.body.specialite) {
      errors.push('Specialty is required for doctors');
    }
    
    // Return errors if any
    if (errors.length > 0) {
      return res.status(400).json({ errors });
    }
    
    next();
  },

  // Keep all your other validation methods unchanged...
  validateLogin: (req, res, next) => {
    const { email, password } = req.body;
    const errors = [];
    
    if (!email) errors.push('Email is required');
    if (!password) errors.push('Password is required');
    
    if (email && !validator.isEmail(email)) {
      errors.push('Invalid email format');
    }
    
    if (errors.length > 0) {
      return res.status(400).json({ errors });
    }
    
    next();
  },

  validateRole: (req, res, next) => {
    const { name, permissions } = req.body;
    const errors = [];
    
    if (!name) errors.push('Role name is required');
    if (!permissions || !Array.isArray(permissions)) {
      errors.push('Permissions must be an array');
    }
    
    if (errors.length > 0) {
      return res.status(400).json({ errors });
    }
    
    next();
  },

  validateRoleAssignment: (req, res, next) => {
    const { userId, roleId } = req.body;
    
    if (!userId) {
      return res.status(400).json({ error: 'User ID is required' });
    }
    
    if (!roleId) {
      return res.status(400).json({ error: 'Role ID is required' });
    }
    
    next();
  },

  validateVerificationCode: (req, res, next) => {
    const { userId, code } = req.body;
    
    if (!userId) {
      return res.status(400).json({ error: 'User ID is required' });
    }
    
    if (!code) {
      return res.status(400).json({ error: 'Verification code is required' });
    }
    
    next();
  },

  sanitizeInput: (req, res, next) => {
    if (req.body) {
      Object.keys(req.body).forEach(key => {
        if (typeof req.body[key] === 'string') {
          req.body[key] = validator.escape(req.body[key]);
        }
      });
    }
    
    if (req.query) {
      Object.keys(req.query).forEach(key => {
        if (typeof req.query[key] === 'string') {
          req.query[key] = validator.escape(req.query[key]);
        }
      });
    }
    
    next();
  }
};