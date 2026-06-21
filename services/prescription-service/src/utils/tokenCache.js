// utils/tokenCache.js
const jwt = require('jsonwebtoken');
const config = require('../config/config');

class TokenCache {
  constructor() {
    this.tokens = new Map(); // userId -> token
    this.secretKey = config.jwt.serviceSecret;
    console.log(`🔐 TokenCache initialized with secret key length: ${this.secretKey.length}`);
    
    // Log first few characters of secret key for debugging
    if (process.env.NODE_ENV !== 'production') {
      console.log(`🔑 Secret key first chars: ${this.secretKey.substring(0, 5)}...`);
    }
  }
  
  /**
   * Add or update a token in the cache
   * @param {String} userId - User ID
   * @param {String} token - JWT token
   */
  setToken(userId, token) {
    this.tokens.set(userId, token);
    console.log(`💾 Token set for user: ${userId}`);
  }
  
  /**
   * Remove a token from the cache
   * @param {String} userId - User ID
   */
  removeToken(userId) {
    this.tokens.delete(userId);
    console.log(`🗑️ Token removed for user: ${userId}`);
  }
  
  /**
   * Verify token and get user data
   * @param {String} token - JWT token
   * @returns {Object|null} Decoded token or null if invalid
   */
  verifyToken(token) {
    try {
      return jwt.verify(token, this.secretKey);
    } catch (error) {
      console.error(`❌ Token verification failed: ${error.message}`);
      
      // In development, decode without verifying
      if (process.env.NODE_ENV !== 'production') {
        console.warn('⚠️ DEVELOPMENT MODE: Decoding token without verification');
        return jwt.decode(token);
      }
      
      return null;
    }
  }
  
  /**
   * Check if user has valid token
   * @param {String} userId - User ID
   * @returns {Boolean} Token validity
   */
  hasValidToken(userId) {
    return this.tokens.has(userId);
  }
  
  /**
   * Get user data from token
   * @param {String} userId - User ID
   * @returns {Object|null} User data
   */
  getUserData(userId) {
    const token = this.tokens.get(userId);
    if (!token) return null;
    
    return this.verifyToken(token);
  }
  
  /**
   * Check if user has permission
   * @param {String} userId - User ID
   * @param {String} permission - Permission to check
   * @returns {Boolean} Permission status
   */
  hasPermission(userId, permission) {
    const userData = this.getUserData(userId);
    
    if (!userData) return false;
    
    // Admin role bypass permission check
    if (userData.role === 'Admin') {
      return true;
    }
    
    return userData.permissions?.includes(permission) === true;
  }
  
  /**
   * Get all cached tokens (for debugging)
   * @returns {Object} Map of userId -> tokenInfo
   */
  getAllTokens() {
    if (process.env.NODE_ENV !== 'production') {
      const result = {};
      this.tokens.forEach((token, userId) => {
        const decoded = jwt.decode(token);
        result[userId] = {
          tokenFirstChars: token.substring(0, 10) + '...',
          decoded: decoded ? {
            iat: decoded.iat,
            exp: decoded.exp,
            role: decoded.role,
            permissions: decoded.permissions
          } : null
        };
      });
      return result;
    }
    return { message: 'Only available in development mode' };
  }
}

module.exports = new TokenCache();