// routes/userRoutes.js - MISE À JOUR avec ORDRE DES ROUTES CORRIGÉ
const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const { authenticate, authorize } = require('../middlewares/authMiddleware');

// Input validation middleware
const { body, param, query, validationResult } = require('express-validator');

// Validation middleware
const handleValidationErrors = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ 
      error: 'Validation failed',
      details: errors.array()
    });
  }
  next();
};

// ✅ MISE À JOUR: Custom validation for additional roles
const validateAdditionalRoles = (req, res, next) => {
  if (req.body.additionalRoles !== undefined) {
    if (!Array.isArray(req.body.additionalRoles)) {
      return res.status(400).json({
        error: 'additionalRoles must be an array of role IDs'
      });
    }
    
    // Validate each role ID format
    for (const roleId of req.body.additionalRoles) {
      if (typeof roleId !== 'string' || !roleId.match(/^[0-9a-fA-F]{24}$/)) {
        return res.status(400).json({
          error: 'Each additional role must be a valid MongoDB ObjectId'
        });
      }
    }
  }
  next();
};

// ✅ IMPORTANT: Routes spécifiques AVANT les routes avec paramètres
// Route pour changement de son propre mot de passe (DOIT être AVANT /:id/password)
router.put('/me/password', 
  authenticate,
  [
    body('currentPassword').notEmpty().withMessage('Current password is required'),
    body('newPassword').isLength({ min: 6 }).withMessage('New password must be at least 6 characters'),
    body('confirmPassword').custom((value, { req }) => {
      if (value !== req.body.newPassword) {
        throw new Error('Password confirmation does not match');
      }
      return true;
    })
  ],
  handleValidationErrors,
  userController.changeOwnPassword
);

// User CRUD routes avec permissions et support multi-rôles
router.get('/', 
  authenticate,
  authorize('view_user'), // ✅ Permission corrigée (singular)
  userController.getAllUsers
);

router.get('/search', 
  authenticate,
  authorize('view_user'),
  query('q').trim().isLength({ min: 2 }).withMessage('Search query must be at least 2 characters'),
  handleValidationErrors,
  userController.searchUsers
);

// Role management routes (AVANT les routes avec :id pour éviter les conflits)
router.get('/roles/all', 
  authenticate,
  authorize('view_user'),
  userController.getAllRoles
);

// Routes avec paramètres :id APRÈS les routes spécifiques
router.get('/:id', 
  authenticate,
  authorize('view_user'),
  param('id').isMongoId().withMessage('Invalid user ID'),
  handleValidationErrors,
  userController.getUserById
);

router.post('/', 
  authenticate,
  authorize('create_user'), // ✅ Permission corrigée (singular)
  [
    body('email').isEmail().withMessage('Valid email is required'),
    body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
    body('firstname').trim().notEmpty().withMessage('First name is required'),
    body('lastname').trim().notEmpty().withMessage('Last name is required'),
    body('role').isMongoId().withMessage('Valid role ID is required'),
    body('specialite').optional().trim(),
    body('active').optional().isBoolean().withMessage('Active must be a boolean'),
    body('additionalRoles').optional().isArray().withMessage('Additional roles must be an array'), // ✅ AJOUTÉ
    body('additionalRoles.*').optional().isMongoId().withMessage('Each additional role must be a valid role ID') // ✅ AJOUTÉ
  ],
  handleValidationErrors,
  validateAdditionalRoles, // ✅ AJOUTÉ
  userController.createUser
);

router.put('/:id', 
  authenticate,
  authorize('update_user'), // ✅ Permission corrigée (singular)
  [
    param('id').isMongoId().withMessage('Invalid user ID'),
    body('email').optional().isEmail().withMessage('Valid email is required'),
    body('password').optional().isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
    body('firstname').optional().trim().notEmpty().withMessage('First name cannot be empty'),
    body('lastname').optional().trim().notEmpty().withMessage('Last name cannot be empty'),
    body('role').optional().isMongoId().withMessage('Valid role ID is required'),
    body('specialite').optional().trim(),
    body('active').optional().isBoolean().withMessage('Active must be a boolean'),
    body('additionalRoles').optional().isArray().withMessage('Additional roles must be an array'), // ✅ AJOUTÉ
    body('additionalRoles.*').optional().isMongoId().withMessage('Each additional role must be a valid role ID') // ✅ AJOUTÉ
  ],
  handleValidationErrors,
  validateAdditionalRoles, // ✅ AJOUTÉ
  userController.updateUser
);

router.delete('/:id', 
  authenticate,
  authorize('delete_user'), // ✅ Permission corrigée (singular)
  param('id').isMongoId().withMessage('Invalid user ID'),
  handleValidationErrors,
  userController.deleteUser
);

// User status management
router.put('/:id/status', 
  authenticate,
  authorize('update_user'), // ✅ Permission corrigée (singular)
  param('id').isMongoId().withMessage('Invalid user ID'),
  handleValidationErrors,
  userController.toggleUserStatus
);

// Route pour changement de mot de passe par admin (APRÈS /me/password)
router.put('/:id/password', 
  authenticate,
  authorize('update_user'), // Ou créer une permission spécifique 'change_password'
  [
    param('id').isMongoId().withMessage('Invalid user ID'),
    body('currentPassword').notEmpty().withMessage('Current password is required'),
    body('newPassword').isLength({ min: 6 }).withMessage('New password must be at least 6 characters'),
    body('confirmPassword').custom((value, { req }) => {
      if (value !== req.body.newPassword) {
        throw new Error('Password confirmation does not match');
      }
      return true;
    })
  ],
  handleValidationErrors,
  userController.changePassword
);

module.exports = router;



/*
L'ordre correct devrait être:
1. PUT /me/password         ← SPÉCIFIQUE (DOIT être en premier)
2. GET /
3. GET /search
4. GET /roles/all           ← SPÉCIFIQUE
5. GET /:id                 ← PARAMÉTRIQUE (après les spécifiques)
6. POST /
7. PUT /:id
8. DELETE /:id
9. PUT /:id/status
10. PUT /:id/password       ← PARAMÉTRIQUE (en dernier)
*/