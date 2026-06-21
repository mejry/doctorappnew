// appointment-service/src/services/authConsumer.js
const jwt = require('jsonwebtoken');
const config = require('../config/config');
const tokenCache = require('../utils/tokenCache');
const logger = require('../config/logger');
const rabbitmq = require('../config/rabbitmq');

async function startAuthConsumer() {
  try {
    // Make sure RabbitMQ is connected
    await rabbitmq.connect();
    
    // Consume messages from auth-tokens queue
    await rabbitmq.consume(config.rabbitmq.queues.authTokens, (message) => {
      logger.info(`Received auth message: ${message.type}`);
      
      try {
        switch (message.type) {
          case 'token.issued':
          case 'token.refreshed':
          case 'token.updated':
            // First try to verify token with our secret
            try {
              // Verify token first to ensure it's valid
              const decodedToken = jwt.verify(message.token, config.jwt.serviceSecret);
              
              // Get user ID (support both formats)
              const userId = decodedToken.id || decodedToken.userId;
              
              if (!userId) {
                logger.warn(`Received token without user ID: ${message.type}`);
                return;
              }
              
              // Store valid token in cache
              tokenCache.setToken(userId, message.token);
              logger.info(`Token stored for user: ${userId}`);
            } catch (jwtError) {
              
              logger.debug(`JWT Service Secret first chars: ${config.jwt.serviceSecret.substring(0, 5)}...`);
              
              // In development, store the token anyway for testing
              if (process.env.NODE_ENV !== 'production' && message.userId) {
                logger.warn('⚠️ DEVELOPMENT MODE: Storing unverified token');
                tokenCache.setToken(message.userId, message.token);
              }
            }
            break;
            
          case 'token.revoked':
            // Remove token from cache
            if (message.userId) {
              tokenCache.removeToken(message.userId);
              logger.info(`Token revoked for user: ${message.userId}`);
            }
            break;
            
          default:
            logger.warn(`Unknown auth message type: ${message.type}`);
        }
      } catch (error) {
        logger.error(`Error processing auth message: ${error.message}`);
      }
    });
    
    logger.info('✅ Started consuming auth messages');
  } catch (error) {
    logger.error('❌ Failed to start auth consumer:', error);
    // Don't throw the error to allow the service to start anyway
  }
}

module.exports = { startAuthConsumer };