// utils/logger.js
const LogEntry = require('../models/LogEntry');

// Create logger utility
const logger = {
  /**
   * Log any user action
   * @param {String} action - Action performed (e.g., "create", "update", "delete")
   * @param {String} resourceType - Type of resource (e.g., "user", "role", "permission")
   * @param {String} resourceId - ID of the resource
   * @param {Object} user - User who performed the action
   * @param {String} message - Log message
   * @param {Object} details - Additional details about the action
   * @param {Object} req - Express request object (optional)
   */
  async logAction(action, resourceType, resourceId, user, message, details = {}, req = null) {
    try {
      const userId = user?._id || user;
      
      // Construct event type from action and resource type
      const eventType = `${action.toUpperCase()}_${resourceType.toUpperCase()}`;
      
      const logData = {
        eventType,
        action,
        resourceType,
        resourceId,
        userId,
        message,
        details,
        metadata: {}
      };
      
      // Add IP and user agent if request is provided
      if (req) {
        logData.ipAddress = req.ip || req.connection.remoteAddress;
        logData.userAgent = req.headers['user-agent'];
      }
      
      await LogEntry.create(logData);
      
      console.log(`Logged action: ${action} on ${resourceType} by user ${userId}`);
    } catch (error) {
      console.error('Logging failed:', error.message);
    }
  },
  
  /**
   * Log authentication events (keeping for backward compatibility)
   * @param {String} eventType - Type of event (LOGIN, REGISTER, etc.)
   * @param {Object} user - User object or userId
   * @param {String} message - Log message
   * @param {Object} req - Express request object (optional)
   * @param {Object} metadata - Additional metadata (optional)
   */
  auth: async (eventType, user, message, req = null, metadata = {}) => {
    try {
      const userId = user?._id || user;
      
      const logData = {
        eventType,
        action: eventType.toLowerCase(),
        resourceType: 'auth',
        userId,
        message,
        metadata
      };
      
      // Add IP and user agent if request is provided
      if (req) {
        logData.ipAddress = req.ip || req.connection.remoteAddress;
        logData.userAgent = req.headers['user-agent'];
      }
      
      await LogEntry.create(logData);
    } catch (error) {
      console.error('Logging failed:', error.message);
    }
  },
  
  /**
   * Log user management events (keeping for backward compatibility)
   * @param {String} eventType - Type of event (USER_CREATED, USER_UPDATED, etc.)
   * @param {Object} admin - Admin performing the action
   * @param {Object} targetUser - Target user
   * @param {String} message - Log message
   * @param {Object} req - Express request object (optional)
   * @param {Object} metadata - Additional metadata (optional)
   */
  user: async (eventType, admin, targetUser, message, req = null, metadata = {}) => {
    try {
      const adminId = admin?._id || admin;
      const targetId = targetUser?._id || targetUser;
      
      const logData = {
        eventType,
        action: eventType.toLowerCase().replace('user_', ''),
        resourceType: 'user',
        resourceId: targetId,
        userId: adminId,
        targetId,
        message,
        metadata
      };
      
      // Add IP and user agent if request is provided
      if (req) {
        logData.ipAddress = req.ip || req.connection.remoteAddress;
        logData.userAgent = req.headers['user-agent'];
      }
      
      await LogEntry.create(logData);
    } catch (error) {
      console.error('User logging failed:', error.message);
    }
  },
  
  /**
   * Log role management events (keeping for backward compatibility)
   * @param {String} eventType - Type of event (ROLE_CREATED, PERMISSION_GRANTED, etc.)
   * @param {Object} admin - Admin performing the action
   * @param {String} roleName - Role name
   * @param {String} message - Log message
   * @param {Object} req - Express request object (optional)
   * @param {Object} metadata - Additional metadata (optional)
   */
  role: async (eventType, admin, roleName, message, req = null, metadata = {}) => {
    try {
      const adminId = admin?._id || admin;
      
      const logData = {
        eventType,
        action: eventType.toLowerCase().replace('role_', '').replace('permission_', ''),
        resourceType: eventType.includes('PERMISSION') ? 'permission' : 'role',
        userId: adminId,
        message,
        metadata: {
          ...metadata,
          roleName
        }
      };
      
      // Add IP and user agent if request is provided
      if (req) {
        logData.ipAddress = req.ip || req.connection.remoteAddress;
        logData.userAgent = req.headers['user-agent'];
      }
      
      await LogEntry.create(logData);
    } catch (error) {
      console.error('Role logging failed:', error.message);
    }
  }
};

module.exports = logger;