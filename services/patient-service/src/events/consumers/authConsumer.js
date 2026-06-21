const jwt = require('jsonwebtoken');
const config = require('../../config/config');
const tokenCache = require('../../utils/tokenCache');
const logger = require('../../utils/logger');
const { connectRabbitMQ } = require('../../utils/rabbit'); // Updated import

async function startAuthConsumer() {
  try {
    const { channel } = await connectRabbitMQ();
    
    await channel.assertQueue(config.rabbitmq.queues.authTokens, { durable: true });
    
    await channel.consume(config.rabbitmq.queues.authTokens, async (message) => {
      if (!message) return;
      
      try {
        const content = JSON.parse(message.content.toString());
        logger.info(`Received auth message of type: ${content.type}`);
        
        switch (content.type) {
          case 'token.issued':
          case 'token.refreshed':
            try {
              // Essayer d'abord avec serviceSecret puis accessSecret
              let decoded;
              try {
                decoded = jwt.verify(content.token, config.jwt.serviceSecret);
              } catch (serviceError) {
                decoded = jwt.verify(content.token, config.jwt.accessSecret);
              }
              
              tokenCache.setToken(decoded.id || decoded.userId, content.token);
              channel.ack(message);
            } catch (error) {
              logger.error(`Token verification failed: ${error.message}`);
              if (process.env.NODE_ENV !== 'production') {
                logger.warn('DEV MODE: Storing unverified token');
                tokenCache.setToken(content.userId, content.token);
                channel.ack(message);
              } else {
                channel.nack(message, false, false); // Ne pas requeue en production
              }
            }
            break;
            
          case 'token.revoked':
            tokenCache.removeToken(content.userId);
            channel.ack(message);
            break;
            
          default:
            logger.warn(`Unknown message type: ${content.type}`);
            channel.ack(message);
        }
      } catch (error) {
        logger.error(`Message processing failed: ${error.message}`);
        channel.nack(message, false, true); // Requeue en cas d'erreur
      }
    });
    
    logger.info('✅ Auth consumer started successfully');
  } catch (error) {
    logger.error('❌ Failed to start auth consumer:', error);
    // Don't exit the process — make this non-fatal so the service can run without RabbitMQ
    return;
  }
}

module.exports = startAuthConsumer;