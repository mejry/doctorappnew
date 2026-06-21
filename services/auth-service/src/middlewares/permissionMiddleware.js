// appointment-service/src/middlewares/permissionMiddleware.js
const logger = require('../config/logger');


const PERMISSIONS = {
  CREATE_APPOINTMENT: 'manage_patients',
  VIEW_APPOINTMENTS: 'manage_patients',
  UPDATE_APPOINTMENT: 'manage_patients',
  CANCEL_APPOINTMENT: 'manage_patients',
  MANAGE_ALL_APPOINTMENTS: 'manage_patients',
  VIEW_ALL_APPOINTMENTS: 'manage_patients',
  SEND_REMINDERS: 'manage_patients',
  VIEW_LOGS: 'view_logs'
};

/**
 * Check if user has specific permission
 * @param {String} permission - Required permission
 */
const hasPermission = (permission) => (req, res, next) => {
  try {
    if (!req.user) {
      logger.error('Permission check failed - no user in request');
      return res.status(401).json({ 
        success: false, 
        message: 'Authentication required' 
      });
    }
    
    logger.info(`Checking permission "${permission}" for user ${req.user.id} with role ${req.user.role}`);
    
    // Admin role always has all permissions
    if (req.user.role === 'Admin') {
      logger.info('User is Admin, granting permission');
      return next();
    }
    
    // Check if user has the required permission
    if (!req.user.permissions || !Array.isArray(req.user.permissions)) {
      logger.error(`User ${req.user.id} has no permissions array. Role: ${req.user.role}`);
      return res.status(403).json({
        success: false,
        message: 'Permission denied - no permissions defined',
        requiredPermission: permission,
        userRole: req.user.role
      });
    }
    
    // Log current permissions for debugging
    logger.info(`User permissions: [${req.user.permissions.join(', ')}]`);
    
    if (!req.user.permissions.includes(permission)) {
      logger.error(`Permission denied: User ${req.user.id} (${req.user.role}) does not have permission: ${permission}`);
      
      return res.status(403).json({
        success: false,
        message: 'Permission denied',
        requiredPermission: permission,
        userRole: req.user.role,
        userPermissions: req.user.permissions
      });
    }
    
    // User has permission, proceed
    logger.info(`Permission granted: User ${req.user.id} has permission: ${permission}`);
    next();
  } catch (error) {
    logger.error('Permission check error:', error);
    return res.status(500).json({
      success: false,
      message: 'Error checking permissions',
      error: error.message
    });
  }
};

/**
 * Check if user has any of the specified permissions
 * @param {Array} permissions - Array of required permissions
 */
const hasAnyPermission = (permissions) => (req, res, next) => {
  try {
    if (!req.user) {
      return res.status(401).json({ 
        success: false, 
        message: 'Authentication required' 
      });
    }
    
    // Admin role always has all permissions
    if (req.user.role === 'Admin') {
      return next();
    }
    
    if (!req.user.permissions || !Array.isArray(req.user.permissions)) {
      return res.status(403).json({
        success: false,
        message: 'Permission denied - no permissions defined'
      });
    }
    
    // Check if user has any of the required permissions
    const hasPermission = permissions.some(permission => 
      req.user.permissions.includes(permission)
    );
    
    if (!hasPermission) {
      logger.error(`Permission denied: User ${req.user.id} lacks any of: ${permissions.join(', ')}`);
      return res.status(403).json({
        success: false,
        message: 'Permission denied',
        requiredPermissions: permissions,
        userPermissions: req.user.permissions
      });
    }
    
    next();
  } catch (error) {
    logger.error('Permission check error:', error);
    return res.status(500).json({
      success: false,
      message: 'Error checking permissions'
    });
  }
};

/**
 * Check if doctor is authorized for this appointment
 * Ensures doctors can only manage their own appointments
 */
const isAuthorizedDoctor = () => async (req, res, next) => {
  try {
    if (!req.user) {
      return res.status(401).json({ 
        success: false, 
        message: 'Authentication required' 
      });
    }
    
    // Admin role can access all appointments
    if (req.user.role === 'Admin' || req.user.role === 'Secretary') {
      return next();
    }
    
    // For doctor role, check if appointment belongs to this doctor
    if (req.user.role === 'Doctor') {
      const appointmentId = req.params.id;
      
      if (!appointmentId) {
        return res.status(400).json({
          success: false,
          message: 'Appointment ID is required'
        });
      }
      
      // Get the appointment to check doctorId
      const Appointment = require('../models/appointment');
      const appointment = await Appointment.findById(appointmentId);
      
      if (!appointment) {
        return res.status(404).json({
          success: false,
          message: 'Appointment not found'
        });
      }
      
      // Check if doctor is authorized for this appointment
      if (appointment.doctorId !== req.user.id) {
        logger.error(`Unauthorized access: Doctor ${req.user.id} attempted to access appointment ${appointmentId} belonging to doctor ${appointment.doctorId}`);
        
        return res.status(403).json({
          success: false,
          message: 'Not authorized to access this appointment'
        });
      }
    }
    
    // User is authorized, proceed
    next();
  } catch (error) {
    logger.error('Authorization check error:', error);
    return res.status(500).json({
      success: false,
      message: 'Error checking authorization'
    });
  }
};

/**
 * Middleware to restrict access to only Admin role
 */
const adminOnly = () => (req, res, next) => {
  if (!req.user) {
    return res.status(401).json({ 
      success: false, 
      message: 'Authentication required' 
    });
  }
  
  if (req.user.role !== 'Admin') {
    logger.error(`Admin access attempt: User ${req.user.id} with role ${req.user.role} tried to access admin-only resource`);
    
    return res.status(403).json({
      success: false,
      message: 'Admin access required'
    });
  }
  
  next();
};

/**
 * Middleware to restrict view access based on user role
 * Doctors can only see their appointments, receptionists and admins can see all
 */
const filterAppointmentsForUser = () => (req, res, next) => {
  if (!req.user) {
    return res.status(401).json({ 
      success: false, 
      message: 'Authentication required' 
    });
  }
  
  logger.info(`Filtering appointments for user ${req.user.id} with role ${req.user.role}`);
  
  // Modify query parameters based on role
  if (req.user.role === 'Doctor') {
    // Force doctorId filter for doctors to only see their appointments
    req.query.doctorId = req.user.id;
    logger.info(`Doctor filter applied: doctorId=${req.user.id}`);
  }
  
  // Admin, Secretary, and Receptionist roles can see all appointments (no filter modification)
  
  next();
};

// Export all middleware functions
module.exports = {
  PERMISSIONS,
  hasPermission,
  hasAnyPermission,
  isAuthorizedDoctor,
  adminOnly,
  filterAppointmentsForUser
};