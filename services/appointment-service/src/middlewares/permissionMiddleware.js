// appointment-service/src/middlewares/permissionMiddleware.js
const logger = require("../config/logger");

/**
 * Simple permission middleware that uses permissions from the token
 * No need to redefine permissions - just check what's in the token
 */

/**
 * Check if user has specific permission
 * @param {String} requiredPermission - Permission to check (from auth service)
 */
const hasPermission = (requiredPermission) => (req, res, next) => {
  try {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: "Authentication required",
      });
    }

    logger.info(
      `Checking permission "${requiredPermission}" for user ${req.user.id} with role ${req.user.role}`,
    );

    // Admin role always has all permissions
    if (req.user.role === "Admin") {
      logger.info("User is Admin, granting permission");
      return next();
    }

    // Check if user has the required permission from token
    if (!req.user.permissions || !Array.isArray(req.user.permissions)) {
      logger.error(`User ${req.user.id} has no permissions in token`);
      return res.status(403).json({
        success: false,
        message: "No permissions found in token",
        userRole: req.user.role,
      });
    }

    // Check if user has the specific permission
    if (!req.user.permissions.includes(requiredPermission)) {
      logger.error(
        `Permission denied: User ${req.user.id} (${req.user.role}) does not have permission: ${requiredPermission}`,
      );
      logger.error(`User permissions: [${req.user.permissions.join(", ")}]`);

      return res.status(403).json({
        success: false,
        message: "Permission denied",
        requiredPermission: requiredPermission,
        userRole: req.user.role,
        userPermissions: req.user.permissions,
      });
    }

    // User has permission, proceed
    logger.info(
      `Permission granted: User ${req.user.id} has permission: ${requiredPermission}`,
    );
    next();
  } catch (error) {
    logger.error("Permission check error:", error);
    return res.status(500).json({
      success: false,
      message: "Error checking permissions",
      error: error.message,
    });
  }
};

/**
 * Check if user has any of the specified permissions
 * @param {Array} requiredPermissions - Array of permissions to check
 */
const hasAnyPermission = (requiredPermissions) => (req, res, next) => {
  try {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: "Authentication required",
      });
    }

    // Admin role always has all permissions
    if (req.user.role === "Admin") {
      return next();
    }

    if (!req.user.permissions || !Array.isArray(req.user.permissions)) {
      return res.status(403).json({
        success: false,
        message: "No permissions found in token",
      });
    }

    // Check if user has any of the required permissions
    const hasPermission = requiredPermissions.some((permission) =>
      req.user.permissions.includes(permission),
    );

    if (!hasPermission) {
      logger.error(
        `Permission denied: User ${req.user.id} lacks any of: ${requiredPermissions.join(", ")}`,
      );
      return res.status(403).json({
        success: false,
        message: "Permission denied",
        requiredPermissions: requiredPermissions,
        userPermissions: req.user.permissions,
      });
    }

    next();
  } catch (error) {
    logger.error("Permission check error:", error);
    return res.status(500).json({
      success: false,
      message: "Error checking permissions",
    });
  }
};

/**
 * Filter appointments based on user role
 * Doctors see only their appointments, others can see all
 */
const filterByRole = () => (req, res, next) => {
  if (!req.user) {
    return res.status(401).json({
      success: false,
      message: "Authentication required",
    });
  }

  // Doctors can only see their own appointments
  if (req.user.role === "Doctor") {
    req.query.doctorId = req.user.id;
    logger.info(`Doctor filter applied: doctorId=${req.user.id}`);
  }

  // Admin, Secretary, and others can see all appointments
  next();
};

/**
 * Check if user can access specific appointment (for doctors)
 */
const canAccessAppointment = () => async (req, res, next) => {
  try {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: "Authentication required",
      });
    }

    // Admin and Secretary can access all appointments
    if (req.user.role === "Admin" || req.user.role === "Secretary") {
      return next();
    }

    // For doctors, check if appointment belongs to them
    if (req.user.role === "Doctor") {
      const appointmentId = req.params.id;

      if (!appointmentId) {
        return res.status(400).json({
          success: false,
          message: "Appointment ID is required",
        });
      }

      const Appointment = require("../models/Appointment");
      const appointment = await Appointment.findById(appointmentId);

      if (!appointment) {
        return res.status(404).json({
          success: false,
          message: "Appointment not found",
        });
      }

      if (appointment.doctorId !== req.user.id) {
        return res.status(403).json({
          success: false,
          message: "Not authorized to access this appointment",
        });
      }
    }

    next();
  } catch (error) {
    logger.error("Authorization check error:", error);
    return res.status(500).json({
      success: false,
      message: "Error checking authorization",
    });
  }
};

module.exports = {
  hasPermission,
  hasAnyPermission,
  filterByRole,
  canAccessAppointment,
};
