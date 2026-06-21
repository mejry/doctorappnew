// middlewares/permission.js
const { 
  PRESCRIPTION, 
  PRESCRIPTION_FILTERS, 
  MEDICATION
} = require('../config/permission');

/**
 * Middleware factory for permission checks
 */
const hasPermission = (permission) => (req, res, next) => {
  try {
    if (!req.user) {
      console.error('❌ Permission check failed - no user in request');
      return res.status(401).json({ 
        success: false, 
        message: 'Authentication required' 
      });
    }
    
    console.log(`🔍 Checking permission "${permission}" for user ${req.user.id} (${req.user.role})`);
    
    // Admin bypass
    if (req.user.role === 'Admin') {
      console.log('👑 User is Admin, granting permission');
      return next();
    }
    
    // Check permissions array
    if (!req.user.permissions || !Array.isArray(req.user.permissions)) {
      console.error(`❌ User ${req.user.id} has no permissions array`);
      return res.status(403).json({
        success: false,
        message: 'Permission denied - no permissions defined',
        requiredPermission: permission,
        userRole: req.user.role
      });
    }
    
    // Check permission
    if (!req.user.permissions.includes(permission)) {
      console.error(`❌ Permission denied: ${req.user.id} lacks ${permission}`);
      return res.status(403).json({
        success: false,
        message: 'Permission denied',
        requiredPermission: permission,
        userPermissions: req.user.permissions
      });
    }
    
    console.log(`✅ Permission granted: ${permission}`);
    next();
  } catch (error) {
    console.error('💥 Permission check error:', error);
    return res.status(500).json({
      success: false,
      message: 'Error checking permissions'
    });
  }
};

/**
 * Middleware to verify staff role (non-patient users)
 */
const isStaff = (req, res, next) => {
  const staffRoles = ['Admin', 'Doctor', 'Secretary', 'Receptionist'];
  
  if (!req.user || !staffRoles.includes(req.user.role)) {
    return res.status(403).json({
      success: false,
      message: 'Access restricted to staff members'
    });
  }
  
  next();
};

/**
 * Middleware to verify doctor role
 */
const isDoctor = (req, res, next) => {
  if (!req.user || req.user.role !== 'Doctor') {
    return res.status(403).json({
      success: false,
      message: 'Access restricted to doctors'
    });
  }
  
  next();
};

/**
 * Middleware to verify admin role
 */
const isAdmin = (req, res, next) => {
  if (!req.user || req.user.role !== 'Admin') {
    return res.status(403).json({
      success: false,
      message: 'Access restricted to administrators'
    });
  }
  
  next();
};

module.exports = {
  PRESCRIPTION,
  PRESCRIPTION_FILTERS,
  MEDICATION,
  hasPermission,
  isStaff,
  isDoctor,
  isAdmin
};