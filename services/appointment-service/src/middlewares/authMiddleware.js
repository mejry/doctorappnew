// src/utils/tokenCache.js
const jwt = require('jsonwebtoken');
const config = require('../config/config');
const logger = require('../config/logger');

class TokenCache {
  constructor() {
    this.tokens = new Map(); // userId -> token
    this.secretKey = config.jwt.serviceSecret;
    logger.info(`TokenCache initialized with secret key length: ${this.secretKey.length}`);
  }
  
  /**
   * Add or update a token in the cache
   * @param {String} userId - User ID
   * @param {String} token - JWT token
   */
  setToken(userId, token) {
    this.tokens.set(userId, token);
    logger.debug(`Token set for user: ${userId}`);
  }
  
  /**
   * Remove a token from the cache
   * @param {String} userId - User ID
   */
  removeToken(userId) {
    this.tokens.delete(userId);
    logger.debug(`Token removed for user: ${userId}`);
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
      logger.error(`Token verification failed: ${error.message}`);
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
}

module.exports = new TokenCache();