// src/config/db.js
const mongoose = require('mongoose');
const config = require('./config');
const logger = require('./logger');

// Connect to MongoDB
const connectDB = async () => {
  try {
    await mongoose.connect(config.mongo.url, config.mongo.options);
    logger.info('MongoDB connected successfully');
    return true;
  } catch (error) {
    logger.error('MongoDB connection error:', error);
    throw error;
  }
};

// Disconnect from MongoDB
const disconnectDB = async () => {
  try {
    await mongoose.disconnect();
    logger.info('MongoDB disconnected successfully');
    return true;
  } catch (error) {
    logger.error('MongoDB disconnection error:', error);
    throw error;
  }
};

module.exports = {
  connectDB,
  disconnectDB
};