// bypass-auth.js - Save this as a temporary version
const logger = require('../config/logger');

function verifyToken(req, res, next) {
  logger.warn('⚠️ Authentication bypass enabled for testing');
  
  // Set mock user for testing
  req.user = {
    id: 'test-doctor-id',
    name: 'Test Doctor',
    role: 'doctor'
  };
  
  next();
}

function isDoctor(req, res, next) {
  next();
}

function isStaff(req, res, next) {
  next(); 
}

function isAdmin(req, res, next) {
  next();
}

function isReceptionist(req, res, next) {
  next();
}

function isReceptionistOrAdmin(req, res, next) {
  next();
}

module.exports = {
  verifyToken,
  isDoctor,
  isStaff,
  isAdmin,
  isReceptionist,
  isReceptionistOrAdmin
};