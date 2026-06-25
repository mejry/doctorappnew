const amqp = require('amqplib');
const { v4: uuidv4 } = require('uuid');
require('dotenv').config();

let channel, connection;

// Initialize RabbitMQ connection
async function connectRabbitMQ() {
  try {
    connection = await amqp.connect(process.env.RABBITMQ_URL);
    channel = await connection.createChannel();
    
    // Declare topic exchange
    await channel.assertExchange('medical_events', 'topic', { durable: true });
    console.log('✅ RabbitMQ connected and exchange ready');
    
    // Handle connection errors
    connection.on('close', () => {
      console.log('RabbitMQ connection closed. Reconnecting...');
      setTimeout(connectRabbitMQ, 5000);
    });

    return { channel, connection };
  } catch (error) {
    console.error('RabbitMQ connection failed:', error);
    throw error;
  }
}

// Publish events to RabbitMQ
async function publishEvent(eventType, routingKey, data) {
  try {
    if (!channel) {
      console.warn(`⚠️ RabbitMQ not connected. Skipping event: ${eventType}`);
      return;
    }

    const message = {
      eventId: uuidv4(),
      eventType,
      timestamp: new Date().toISOString(),
      data
    };

    channel.publish(
      'medical_events',
      routingKey,
      Buffer.from(JSON.stringify(message)),
      { persistent: true } // Survive broker restarts
    );

    console.log(`📤 Event published: ${eventType}`);
  } catch (error) {
    console.warn(`⚠️ Failed to publish event ${eventType}, but continuing without it.`);
    // Do not throw error so the API doesn't return 500
  }
}

module.exports = {
  connectRabbitMQ,
  publishEvent,
  getChannel: () => channel,
  getConnection: () => connection
};