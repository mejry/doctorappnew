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
    if (!channel) await connectRabbitMQ();

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
    console.error('Failed to publish event:', error);
    throw error;
  }
}

module.exports = {
  connectRabbitMQ,
  publishEvent,
  getChannel: () => channel,
  getConnection: () => connection
};