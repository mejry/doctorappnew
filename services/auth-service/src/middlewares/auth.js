// appointment-service/src/middlewares/auth.js
const jwt = require('jsonwebtoken');
const config = require('../config/config');
const logger = require('../config/logger');

/**
 * Authenticate and verify JWT token
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 * @param {Function} next - Express next middleware function
 */
const verifyToken = (req, res, next) => {
  try {
    // Get token from authorization header
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ 
        success: false, 
        message: 'Authentication required - Bearer token missing' 
      });
    }
    
    const token = authHeader.split(' ')[1];
    
    if (!token) {
      return res.status(401).json({ 
        success: false, 
        message: 'Authentication required - Token missing' 
      });
    }
    
    logger.info(`Processing token: ${token.substring(0, 15)}...`);
    
    let decoded;
    
    try {
      // First try to verify the token with our service secret
      decoded = jwt.verify(token, config.jwt.serviceSecret);
      logger.info('Token verified successfully with service secret');
    } catch (verifyError) {
      logger.error(`Token verification failed: ${verifyError.message}`);
      
      // In development, try to decode without verification
      if (process.env.NODE_ENV !== 'production') {
        logger.warn('⚠️ DEVELOPMENT MODE: Attempting to decode token without verification');
        decoded = jwt.decode(token);
        
        if (!decoded) {
          return res.status(401).json({ 
            success: false, 
            message: 'Invalid token format' 
          });
        }
      } else {
        return res.status(401).json({ 
          success: false, 
          message: 'Invalid or expired token' 
        });
      }
    }
    
    // Extract user information from token
    const userId = decoded.id || decoded.userId;
    const userRole = decoded.role;
    const userPermissions = decoded.permissions || [];
    const userEmail = decoded.email;
    
    // Validate required fields
    if (!userId) {
      logger.error('Token missing user ID:', decoded);
      return res.status(401).json({ 
        success: false, 
        message: 'Invalid token - missing user ID' 
      });
    }
    
    if (!userRole) {
      logger.error('Token missing user role:', decoded);
      return res.status(401).json({ 
        success: false, 
        message: 'Invalid token - missing user role' 
      });
    }
    
    // Set comprehensive user data in request
    req.user = {
      id: userId,
      role: userRole,
      permissions: userPermissions,
      email: userEmail
    };
    
    logger.info(`User authenticated: ID=${userId}, Role=${userRole}, Permissions=[${userPermissions.join(', ')}]`);
    
    next();
  } catch (error) {
    logger.error(`Authentication error: ${error.message}`);
    return res.status(500).json({ 
      success: false, 
      message: 'Authentication processing error',
      error: error.message
    });
  }
};

// Check if user is staff (doctor, receptionist, or admin)
const isStaff = (req, res, next) => {
  if (!req.user) {
    return res.status(401).json({ 
      success: false, 
      message: 'Authentication required' 
    });
  }
  
  const staffRoles = ['Doctor', 'Receptionist', 'Admin', 'Secretary'];
  
  if (!staffRoles.includes(req.user.role)) {
    logger.warn(`Non-staff access attempt by user ${req.user.id} with role ${req.user.role}`);
    return res.status(403).json({ 
      success: false, 
      message: 'Staff access required' 
    });
  }
  
  logger.info(`Staff access granted for user ${req.user.id} with role ${req.user.role}`);
  next();
};

// Check if user is a doctor
const isDoctor = (req, res, next) => {
  if (!req.user) {
    return res.status(401).json({ 
      success: false, 
      message: 'Authentication required' 
    });
  }
  
  if (req.user.role !== 'Doctor' && req.user.role !== 'Admin') {
    logger.warn(`Non-doctor access attempt by user ${req.user.id} with role ${req.user.role}`);
    return res.status(403).json({ 
      success: false, 
      message: 'Doctor access required' 
    });
  }
  
  next();
};

// Check if user is admin or receptionist
const isReceptionistOrAdmin = (req, res, next) => {
  if (!req.user) {
    return res.status(401).json({ 
      success: false, 
      message: 'Authentication required' 
    });
  }
  
  const allowedRoles = ['Receptionist', 'Admin', 'Secretary'];
  
  if (!allowedRoles.includes(req.user.role)) {
    logger.warn(`Unauthorized access attempt by user ${req.user.id} with role ${req.user.role}`);
    return res.status(403).json({ 
      success: false, 
      message: 'Receptionist or Admin access required' 
    });
  }
  
  next();
};

module.exports = {
  verifyToken,
  isStaff,
  isDoctor,
  isReceptionistOrAdmin
};