// routes/authRoutes.js - Version mise à jour avec bonnes permissions
const express = require('express');
const router = express.Router();
const roleService = require('../services/roleService');
const User = require('../models/User');   
// Controllers
const authController = require('../controllers/authController');
const logController = require('../controllers/logController');
const roleController = require('../controllers/roleController');

// Middlewares
const { 
  authenticate, 
  authorize,
  authenticateService,
  checkRole,
  authorizeAny
} = require('../middlewares/authMiddleware');

const { 
  validateLogin, 
  validateRegister,
  validateRole,
  validateRoleAssignment,
  validateVerificationCode,
  sanitizeInput
} = require('../middlewares/validationMiddleware');

// Rate limiting middleware
const rateLimit = require('express-rate-limit');

// Create rate limiters
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 10, // 10 requests per IP
  message: 'Too many login attempts, please try again later'
});

const registerLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 5, // 5 requests per IP
  message: 'Too many registration attempts, please try again later'
});

const resetLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 3, // 3 requests per IP
  message: 'Too many password reset attempts, please try again later'
});

// Apply sanitization to all routes
router.use(sanitizeInput);

// ==================== Public Routes ====================

// Authentication routes
router.post('/login', loginLimiter, validateLogin, authController.login);
router.post('/register', registerLimiter, validateRegister, authController.register);
router.post('/refresh-token', authController.refreshToken);
router.post('/logout', authController.logout);
router.post('/forget-password', resetLimiter, (req, res, next) => {
  const { email } = req.body;
  
  if (!email) {
    return res.status(400).json({ error: 'Email is required' });
  }
  
  // Basic email validation
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    return res.status(400).json({ error: 'Invalid email format' });
  }
  
  next();
}, authController.forgetPassword);

router.post('/change-password', 
  authenticate, // User must be logged in
  (req, res, next) => {
    const { currentPassword, newPassword, confirmPassword } = req.body;
    
    // Basic validation
    if (!currentPassword || !newPassword || !confirmPassword) {
      return res.status(400).json({ 
        error: 'Current password, new password, and confirm password are required' 
      });
    }
    
    if (newPassword !== confirmPassword) {
      return res.status(400).json({ 
        error: 'New password and confirm password do not match' 
      });
    }
    
    if (newPassword.length < 6) {
      return res.status(400).json({ 
        error: 'New password must be at least 6 characters long' 
      });
    }
    
    next();
  }, 
  authController.changePassword
);

// Two-factor authentication routes
router.post('/2fa/send', loginLimiter, authController.send2FACode);
router.post('/2fa/verify', validateVerificationCode, authController.verify2FA);

// Service authentication (for microservice communication)
router.post('/service-token', authController.getServiceToken);

// ==================== Protected Routes ====================

// User routes
router.get('/me', authenticate, (req, res) => {
  res.json({ user: req.user });
});

router.post('/2fa/toggle', authenticate, authController.toggle2FA);

// ✅ Role management routes - Permissions simplifiées
router.get('/roles', 
  authenticate, 
  authorizeAny(['view_role', 'create_role', 'update_role']), 
  roleController.getRoles
);

router.get('/roles/:roleId', 
  authenticate, 
  authorize('view_role'), 
  roleController.getRoleById
);

router.post('/roles', 
  authenticate, 
  authorize('create_role'), 
  validateRole, 
  roleController.createRole
);

router.put('/roles/:roleId', 
  authenticate, 
  authorize('update_role'), 
  validateRole, 
  roleController.updateRole
);

router.delete('/roles/:roleId', 
  authenticate, 
  authorize('delete_role'), 
  roleController.deleteRole
);

router.post('/assign-role', 
  authenticate, 
  authorize('update_user'), 
  (req, res, next) => {
    const { userId, roleId } = req.body;
    
    if (!userId || !roleId) {
      return res.status(400).json({ error: 'User ID and Role ID are required' });
    }
    
    next();
  },
  roleController.assignRole
);

// ✅ Bulk assign users to role
router.post('/bulk-assign-role', 
  authenticate, 
  authorize('update_user'), 
  (req, res, next) => {
    const { userIds, roleId } = req.body;
    
    if (!Array.isArray(userIds) || !roleId) {
      return res.status(400).json({ error: 'User IDs array and Role ID are required' });
    }
    
    next();
  },
  roleController.bulkAssignRole
);

// ✅ Get users assigned to a specific role
router.get('/roles/:roleId/users', 
  authenticate, 
  authorize('view_user'), 
  roleController.getUsersByRole
);

// ✅ NEW ROUTES FOR DYNAMIC PERMISSIONS
// Get all unique permissions from all roles
router.get('/permissions', 
  authenticate, 
  authorizeAny(['update_role', 'create_role']), 
  (req, res) => {
    // ✅ Return the simplified permissions list
    const allPermissions = [
      // User management
      'view_user',
      'create_user', 
      'update_user',
      'delete_user',
      
      // Role management
      'view_role',
      'create_role',
      'update_role',
      'delete_role',
      
      // Patient management
      'view_patient',
      'create_patient',
      'update_patient', 
      'delete_patient',
      
      // Consultation management
      'view_consultation',
      'create_consultation',
      'update_consultation',
      'delete_consultation',
      
      // Prescription management
      'view_prescription',
      'create_prescription',
      'update_prescription',
      'delete_prescription'
    ];
    
    res.json(allPermissions);
  }
);

// Add a permission to a role
router.post('/roles/:roleId/permissions', 
  authenticate, 
  authorize('update_role'), 
  (req, res) => {
    const { roleId } = req.params;
    const { permission } = req.body;
    
    if (!permission) {
      return res.status(400).json({ error: 'Permission name is required' });
    }
    
    roleService.addPermission(roleId, permission, req.user.id, req)
      .then(role => res.json(role))
      .catch(err => res.status(400).json({ error: err.message }));
  }
);

// Remove a permission from a role
router.delete('/roles/:roleId/permissions/:permission', 
  authenticate, 
  authorize('update_role'), 
  (req, res) => {
    const { roleId, permission } = req.params;
    
    roleService.removePermission(roleId, permission, req.user.id, req)
      .then(role => res.json(role))
      .catch(err => res.status(400).json({ error: err.message }));
  }
);
// Route pour obtenir tous les utilisateurs (pour l'interface d'assignation de rôles)
router.get('/users', 
  authenticate, 
  authorize('view_user'), 
  roleController.getUsers
);

// ✅ Nouvelle route pour retirer un rôle d'un utilisateur
router.post('/remove-role', 
  authenticate, 
  authorize('update_user'), 
  (req, res, next) => {
    const { userId, roleId } = req.body;
    
    if (!userId || !roleId) {
      return res.status(400).json({ error: 'User ID and Role ID are required' });
    }
    
    next();
  },
  roleController.removeRoleFromUser
);

// ✅ Route pour obtenir tous les utilisateurs avec leurs rôles détaillés
router.get('/users-with-roles', 
  authenticate, 
  authorize('view_user'), 
  roleController.getUsersWithRoles
);

// Route to get a user's roles
router.get('/users/:userId/roles', 
  authenticate, 
  authorize('view_user'), 
  (req, res) => {
    const { userId } = req.params;
    
    User.findById(userId)
      .populate('role')
      .then(user => {
        if (!user) {
          return res.status(404).json({ error: 'User not found' });
        }
        res.json({ role: user.role });
      })
      .catch(err => res.status(500).json({ error: err.message }));
  }
);

// Service routes (microservice communication)
router.post('/service/validate-token', 
  authenticateService, 
  (req, res) => {
    res.json({ valid: true, service: req.service });
  }
);

module.exports = router;