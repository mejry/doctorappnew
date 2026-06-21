// middlewares/securityMiddleware.js
const helmet = require('helmet');
const xss = require('xss-clean');
const mongoSanitize = require('express-mongo-sanitize');
const hpp = require('hpp');
const cors = require('cors');
const logger = require('../utils/logger');

module.exports = {
  /**
   * Apply security middleware to Express app
   * @param {Object} app - Express app
   */
  applySecurityMiddleware: (app) => {
    // Enable CORS
    app.use(cors({
      origin: process.env.CLIENT_URL || 'http://localhost:3000',
      credentials: true, // Allow cookies with CORS
      methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
      allowedHeaders: ['Content-Type', 'Authorization'],
      exposedHeaders: ['Content-Length', 'X-Request-Id'],
      maxAge: 86400 // Cache preflight requests for 24 hours
    }));

    // Set security HTTP headers
    app.use(helmet());
    
    // Prevent XSS attacks
    app.use(xss());
    
    // Sanitize data to prevent NoSQL query injection
    app.use(mongoSanitize());
    
    // Prevent HTTP parameter pollution
    app.use(hpp());
    
    // Rate limiting for all routes
    const rateLimit = require('express-rate-limit');
    
    const globalLimiter = rateLimit({
      windowMs: 15 * 60 * 1000, // 15 minutes
      max: 100, // 100 requests per IP per 15 minutes
      message: 'Too many requests from this IP, please try again later',
      standardHeaders: true, // Return rate limit info in the `RateLimit-*` headers
      legacyHeaders: false, // Disable the `X-RateLimit-*` headers
    });
    
    app.use(globalLimiter);
    
    // Add secure headers for tokens
    app.use((req, res, next) => {
      // Set secure cookie policy
      res.cookie('cookiePolicy', 'secure', {
        httpOnly: true,
        secure: process.env.NODE_ENV === 'production',
        sameSite: 'strict'
      });
      
      // Set Content Security Policy
      res.setHeader(
        'Content-Security-Policy',
        "default-src 'self'; script-src 'self'; style-src 'self'; img-src 'self' data:; font-src 'self' data:; connect-src 'self'"
      );
      
      next();
    });
    

    app.use((req, res, next) => {
      // Log unusual request methods
      const validMethods = ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'];
      
      if (!validMethods.includes(req.method)) {
        logger.auth(
          'SECURITY_WARNING',
          'system',
          `Unusual HTTP method: ${req.method}`,
          req,
          { path: req.path }
        );
      }
      
      // Log potential security issues in headers
      const suspiciousHeaders = [
        'x-forwarded-for', 
        'forwarded',
        'x-real-ip'
      ];
      
      for (const header of suspiciousHeaders) {
        if (req.headers[header]) {
          const headerValue = Array.isArray(req.headers[header])
            ? req.headers[header].join(', ')
            : req.headers[header];
            
          logger.auth(
            'SECURITY_WARNING',
            'system',
            `Suspicious header: ${header}`,
            req,
            { headerValue }
          );
        }
      }
      
      next();
    });
    
    return app;
  }
};