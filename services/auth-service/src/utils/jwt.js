// utils/jwt.js
const jwt = require('jsonwebtoken');

// Get secrets from environment variables
const ACCESS_TOKEN_SECRET = process.env.JWT_ACCESS_SECRET || 'access_secret';
const REFRESH_TOKEN_SECRET = process.env.JWT_REFRESH_SECRET || 'refresh_secret';
const SERVICE_TOKEN_SECRET = process.env.JWT_SERVICE_SECRET || 'service_secret';

// Set token expiration times
const ACCESS_TOKEN_EXPIRY = process.env.ACCESS_TOKEN_EXPIRY || '15m';
const REFRESH_TOKEN_EXPIRY = process.env.REFRESH_TOKEN_EXPIRY || '7d';
const SERVICE_TOKEN_EXPIRY = process.env.SERVICE_TOKEN_EXPIRY || '1h';

module.exports = {
  // Generate JWT for user authentication
  generateAccessToken: (payload) => {
    return jwt.sign(payload, ACCESS_TOKEN_SECRET, { expiresIn: ACCESS_TOKEN_EXPIRY });
  },

  // Generate refresh token for getting new access tokens
  generateRefreshToken: (userId) => {
    return jwt.sign({ id: userId }, REFRESH_TOKEN_SECRET, { expiresIn: REFRESH_TOKEN_EXPIRY });
  },

  // Generate token for service-to-service communication
  generateServiceToken: (serviceInfo) => {
    return jwt.sign(serviceInfo, SERVICE_TOKEN_SECRET, { expiresIn: SERVICE_TOKEN_EXPIRY });
  },

  // Verify access token
  verifyAccessToken: (token) => {
    try {
      return jwt.verify(token, ACCESS_TOKEN_SECRET);
    } catch (error) {
      throw new Error('Invalid access token');
    }
  },

  // Verify refresh token
  verifyRefreshToken: (token) => {
    try {
      return jwt.verify(token, REFRESH_TOKEN_SECRET);
    } catch (error) {
      throw new Error('Invalid refresh token');
    }
  },

  // Verify service token
  verifyServiceToken: (token) => {
    try {
      return jwt.verify(token, SERVICE_TOKEN_SECRET);
    } catch (error) {
      throw new Error('Invalid service token');
    }
  }
};