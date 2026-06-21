// middlewares/authMiddleware.js - Version simplifiée
const jwtUtil = require('../utils/jwt');
const User = require('../models/User');
const Role = require('../models/Role');
const logger = require('../utils/logger');

module.exports = {
  /**
   * Authenticate user with JWT - Version simplifiée
   */
  authenticate: async (req, res, next) => {
    try {
      console.log('🔐 Authentication middleware triggered');
      
      const authHeader = req.headers.authorization;
      
      if (!authHeader || !authHeader.startsWith('Bearer ')) {
        console.log('❌ No Authorization header provided');
        return res.status(401).json({ 
          error: 'Authentication required',
          message: 'Authorization header with Bearer token is required'
        });
      }
      
      const token = authHeader.substring(7);
      
      if (!token) {
        console.log('❌ No token provided after Bearer');
        return res.status(401).json({ 
          error: 'Authentication required',
          message: 'Bearer token is required'
        });
      }
      
      console.log('✅ Token found in Authorization header');
      
      const decoded = jwtUtil.verifyAccessToken(token);
      console.log('✅ Token decoded successfully:', { 
        id: decoded.id, 
        email: decoded.email 
      });
      
      // ✅ Récupérer l'utilisateur avec TOUS ses rôles
      const user = await User.findById(decoded.id)
        .populate('role', 'name permissions')
        .populate('additionalRoles', 'name permissions');
      
      if (!user) {
        console.log('❌ User not found in database');
        return res.status(401).json({ 
          error: 'Invalid token',
          message: 'User not found'
        });
      }
      
      if (!user.active) {
        console.log('❌ User account is inactive');
        return res.status(401).json({ 
          error: 'Account disabled',
          message: 'User account is disabled'
        });
      }
      
      if (!user.role) {
        console.log('❌ User has no primary role assigned');
        return res.status(401).json({ 
          error: 'Account configuration error',
          message: 'User has no primary role assigned'
        });
      }
      
      console.log('✅ User authenticated successfully:', user.email);
      console.log('🎭 User primary role:', user.role?.name);
      console.log('🎭 User additional roles:', user.additionalRoles?.map(r => r.name));
      
      // ✅ Calculer toutes les permissions depuis tous les rôles
      const allPermissions = user.getAllPermissions();
      const allRoleNames = user.getAllRoleNames();
      
      console.log('🔑 User permissions:', allPermissions);
      
      // Set user data in request object
      req.user = {
        id: user._id,
        email: user.email,
        firstname: user.firstname,
        lastname: user.lastname,
        primaryRole: user.role?.name || null,
        allRoles: allRoleNames,
        permissions: allPermissions,
        active: user.active,
        emailVerified: user.emailVerified
      };
      
      console.log('✅ Authentication successful, proceeding to next middleware');
      next();
      
    } catch (error) {
      console.log('❌ Authentication error:', error.message);
      
      if (error.name === 'TokenExpiredError') {
        console.log('🔄 Token has expired');
        return res.status(401).json({ 
          error: 'Token expired',
          message: 'Access token has expired',
          refreshRequired: true
        });
      }
      
      if (error.name === 'JsonWebTokenError') {
        console.log('🔧 Invalid JWT token');
        return res.status(401).json({ 
          error: 'Invalid token',
          message: 'JWT token is malformed or invalid'
        });
      }
      
      console.error('💥 Unexpected authentication error:', error);
      return res.status(401).json({ 
        error: 'Authentication failed',
        message: 'Unable to authenticate user'
      });
    }
  },
  
  /**
   * Check if user has required permission
   */
  authorize: (requiredPermission) => {
    return (req, res, next) => {
      try {
        console.log('🛡️ Authorization middleware triggered');
        console.log('Required permission:', requiredPermission);
        
        if (!req.user) {
          console.log('❌ No authenticated user found');
          return res.status(401).json({ 
            error: 'Authentication required',
            message: 'User must be authenticated to access this resource'
          });
        }
        
        console.log('👤 Authorizing user:', req.user.email);
        console.log('🎭 User primary role:', req.user.primaryRole);
        console.log('🎭 User all roles:', req.user.allRoles);
        console.log('🔑 User permissions:', req.user.permissions);
        
        // ✅ Admin role has all permissions
        if (req.user.allRoles && req.user.allRoles.includes('Admin')) {
          console.log('✅ Admin access granted (bypass permission check)');
          return next();
        }
        
        // ✅ Check if user has the required permission from ANY role
        if (!req.user.permissions || !Array.isArray(req.user.permissions)) {
          console.log('❌ User has no permissions array');
          return res.status(403).json({ 
            error: 'Access denied',
            message: 'User has no permissions configured'
          });
        }
        
        if (!req.user.permissions.includes(requiredPermission)) {
          console.log('❌ Permission denied');
          console.log('Required permission:', requiredPermission);
          console.log('User permissions:', req.user.permissions);
          
          return res.status(403).json({ 
            error: 'Insufficient permissions',
            message: `This action requires the '${requiredPermission}' permission`,
            required: requiredPermission,
            userRoles: req.user.allRoles
          });
        }
        
        console.log('✅ Permission granted:', requiredPermission);
        next();
        
      } catch (error) {
        console.error('💥 Authorization middleware error:', error);
        return res.status(500).json({ 
          error: 'Authorization check failed',
          message: 'Unable to verify user permissions'
        });
      }
    };
  },
  
  /**
   * Check if user has ANY of the required permissions
   */
  authorizeAny: (requiredPermissions) => {
    return (req, res, next) => {
      try {
        console.log('🛡️ AuthorizeAny middleware triggered');
        console.log('Required permissions (any of):', requiredPermissions);
        
        if (!req.user) {
          return res.status(401).json({ 
            error: 'Authentication required',
            message: 'User must be authenticated to access this resource'
          });
        }
        
        if (!Array.isArray(requiredPermissions) || requiredPermissions.length === 0) {
          console.error('❌ Invalid requiredPermissions parameter');
          return res.status(500).json({ 
            error: 'Configuration error',
            message: 'Invalid permission configuration'
          });
        }
        
        // ✅ Admin role has all permissions
        if (req.user.allRoles && req.user.allRoles.includes('Admin')) {
          console.log('✅ Admin access granted (bypass permission check)');
          return next();
        }
        
        // ✅ Check if user has any of the required permissions from ANY role
        const hasPermission = requiredPermissions.some(permission => 
          req.user.permissions && req.user.permissions.includes(permission)
        );
        
        if (!hasPermission) {
          console.log('❌ None of required permissions found');
          console.log('Required (any of):', requiredPermissions);
          console.log('User permissions:', req.user.permissions);
          
          return res.status(403).json({ 
            error: 'Insufficient permissions',
            message: `This action requires any of these permissions: ${requiredPermissions.join(', ')}`,
            required: requiredPermissions,
            userRoles: req.user.allRoles
          });
        }
        
        const grantedPermission = requiredPermissions.find(permission => 
          req.user.permissions.includes(permission)
        );
        
        console.log('✅ Permission granted:', grantedPermission);
        next();
        
      } catch (error) {
        console.error('💥 AuthorizeAny middleware error:', error);
        return res.status(500).json({ 
          error: 'Authorization check failed',
          message: 'Unable to verify user permissions'
        });
      }
    };
  },
  
  /**
   * Check if user has specific role
   */
  checkRole: (requiredRole) => {
    return (req, res, next) => {
      try {
        console.log('👑 Role check middleware triggered');
        console.log('Required role:', requiredRole);
        
        if (!req.user) {
          return res.status(401).json({ 
            error: 'Authentication required',
            message: 'User must be authenticated to access this resource'
          });
        }
        
        console.log('User roles:', req.user.allRoles);
        
        // ✅ Admin role can access everything
        if (req.user.allRoles && req.user.allRoles.includes('Admin')) {
          console.log('✅ Admin access granted (bypass role check)');
          return next();
        }
        
        // ✅ Check if user has the required role
        if (!req.user.allRoles || !req.user.allRoles.includes(requiredRole)) {
          console.log('❌ Role check failed');
          
          return res.status(403).json({ 
            error: 'Role access denied',
            message: `This action requires '${requiredRole}' role`,
            required: requiredRole,
            userRoles: req.user.allRoles
          });
        }
        
        console.log('✅ Role check passed');
        next();
        
      } catch (error) {
        console.error('💥 Role check middleware error:', error);
        return res.status(500).json({ 
          error: 'Role check failed',
          message: 'Unable to verify user role'
        });
      }
    };
  },
  
  // Autres méthodes restent identiques...
  authenticateService: (req, res, next) => {
    try {
      console.log('🔧 Service authentication middleware triggered');
      
      const authHeader = req.headers.authorization;
      
      if (!authHeader || !authHeader.startsWith('Service ')) {
        console.log('❌ No Service token provided');
        return res.status(401).json({ 
          error: 'Service authentication required',
          message: 'Authorization header with Service token is required'
        });
      }
      
      const token = authHeader.substring(8);
      
      if (!token) {
        return res.status(401).json({ 
          error: 'Service authentication required',
          message: 'Service token is required'
        });
      }
      
      const decoded = jwtUtil.verifyServiceToken(token);
      
      req.service = {
        id: decoded.serviceId || decoded.id,
        name: decoded.service || decoded.serviceName,
        permissions: decoded.permissions || [],
        issuedAt: decoded.iat
      };
      
      console.log('✅ Service authenticated:', req.service.name);
      next();
      
    } catch (error) {
      console.error('❌ Service authentication error:', error.message);
      
      if (error.name === 'TokenExpiredError') {
        return res.status(401).json({ 
          error: 'Service token expired',
          message: 'Service token has expired'
        });
      }
      
      return res.status(401).json({ 
        error: 'Invalid service token',
        message: 'Service token is invalid or malformed'
      });
    }
  },
  
  /**
   * Optional authentication - user can be anonymous
   */
  optionalAuth: async (req, res, next) => {
    try {
      const authHeader = req.headers.authorization;
      
      if (!authHeader || !authHeader.startsWith('Bearer ')) {
        console.log('📝 No authentication provided - proceeding as anonymous');
        req.user = null;
        return next();
      }
      
      const token = authHeader.substring(7);
      const decoded = jwtUtil.verifyAccessToken(token);
      const user = await User.findById(decoded.id)
        .populate('role', 'name permissions')
        .populate('additionalRoles', 'name permissions');
      
      if (user && user.active && user.role) {
        const allPermissions = user.getAllPermissions();
        const allRoleNames = user.getAllRoleNames();
        
        req.user = {
          id: user._id,
          email: user.email,
          primaryRole: user.role?.name || null,
          allRoles: allRoleNames,
          permissions: allPermissions
        };
        console.log('✅ Optional auth - user authenticated:', user.email);
      } else {
        console.log('📝 Optional auth - invalid token, proceeding as anonymous');
        req.user = null;
      }
      
      next();
      
    } catch (error) {
      console.log('📝 Optional auth - token validation failed, proceeding as anonymous');
      req.user = null;
      next();
    }
  }
};