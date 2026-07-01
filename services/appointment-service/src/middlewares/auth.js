// appointment-service/src/middlewares/auth.js
const jwt = require('jsonwebtoken');
const config = require('../config/config');
const logger = require('../config/logger');

/**
 * Authenticate and verify JWT token.
 */
const verifyToken = (req, res, next) => {
  try {
    const token = req.headers.authorization?.split(' ')[1];

    if (!token) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required'
      });
    }

    logger.info(`Token received: ${token.substring(0, 15)}...`);

    let decoded;
    try {
      decoded = jwt.verify(token, config.jwt.accessSecret);
      logger.info('Access token verified successfully');
    } catch (accessVerifyError) {
      try {
        decoded = jwt.verify(token, config.jwt.serviceSecret);
        logger.info('Service token verified successfully');
      } catch (serviceVerifyError) {
        logger.error(
          `Token verification failed: ${accessVerifyError.message}; ${serviceVerifyError.message}`
        );

        if (process.env.NODE_ENV !== 'production') {
          logger.warn('DEVELOPMENT MODE: Decoding token without verification');
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
    }

    const userId = decoded.id || decoded.userId;
    const userRole = decoded.role;
    const userPermissions = decoded.permissions || [];
    const userEmail = decoded.email;

    if (!userId || !userRole) {
      logger.error('Token missing required fields:', decoded);
      return res.status(401).json({
        success: false,
        message: 'Invalid token - missing user data'
      });
    }

    req.user = {
      id: userId,
      role: userRole,
      permissions: userPermissions,
      email: userEmail
    };

    logger.info(
      `User authenticated: ID=${userId}, Role=${userRole}, Permissions=[${userPermissions.join(', ')}]`
    );
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

// Check if user is staff.
const isStaff = (req, res, next) => {
  if (!req.user) {
    return res.status(401).json({
      success: false,
      message: 'Authentication required'
    });
  }

  const staffRoles = ['Doctor', 'Receptionist', 'Admin', 'Secretary'];

  if (!staffRoles.includes(req.user.role)) {
    logger.warn(
      `Non-staff access attempt by user ${req.user.id} with role ${req.user.role}`
    );
    return res.status(403).json({
      success: false,
      message: 'Staff access required'
    });
  }

  next();
};

module.exports = {
  verifyToken,
  isStaff
};
