// events/consumers/authConsumer.js
const jwt = require('jsonwebtoken');
const config = require('../../config/config');
const tokenCache = require('../../utils/tokenCache');
const logger = require('../../utils/logger');
const { connectRabbitMQ } = require('../../utils/rabbit');

async function startAuthConsumer() {
  try {
    const { channel } = await connectRabbitMQ();
    
    await channel.assertQueue(config.rabbitmq.queues.authTokens, { durable: true });
    
    await channel.consume(config.rabbitmq.queues.authTokens, async (message) => {
      if (!message) return;
      
      try {
        const content = JSON.parse(message.content.toString());
        console.log(`🔐 Received auth message of type: ${content.type}`);
        
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
              console.log(`✅ Token cached for user: ${decoded.id || decoded.userId}`);
            } catch (error) {
              console.error(`❌ Token verification failed: ${error.message}`);
              if (process.env.NODE_ENV !== 'production') {
                console.warn('⚠️ DEV MODE: Storing unverified token');
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
            console.log(`🗑️ Token removed for user: ${content.userId}`);
            break;
            
          default:
            console.warn(`❓ Unknown message type: ${content.type}`);
            channel.ack(message);
        }
      } catch (error) {
        console.error(`💥 Message processing failed: ${error.message}`);
        channel.nack(message, false, true); // Requeue en cas d'erreur
      }
    });
    
    console.log('✅ Auth consumer started successfully for prescription service');
  } catch (error) {
    console.error('❌ Failed to start auth consumer:', error);
    // Non-fatal in development - continue without RabbitMQ
    return;
  }
}

module.exports = startAuthConsumer;