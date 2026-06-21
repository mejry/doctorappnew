// auth-service/src/utils/rabbitmq.js
const amqp = require('amqplib');

// Import a simple console logger until your actual logger is properly set up
const logger = {
  info: (message, ...args) => console.log(`[INFO] ${message}`, ...args),
  warn: (message, ...args) => console.log(`[WARN] ${message}`, ...args),
  error: (message, ...args) => console.error(`[ERROR] ${message}`, ...args),
  debug: (message, ...args) => console.log(`[DEBUG] ${message}`, ...args)
};

let channel, connection;

async function connectRabbitMQ() {
  try {
    // Use environment variable or fallback to default
    const rabbitMqUrl = process.env.RABBITMQ_URL || 'amqp://localhost';
    
    connection = await amqp.connect(rabbitMqUrl);
    channel = await connection.createChannel();
    
    // Define queues
    const queues = [
      'auth-tokens', 
      'system-logs', 
      'appointment-created', 
      'appointment-updated', 
      'appointment-cancelled',
      'patient-events' ,
      'consultation-events',
      'prescription-events',
    ];
    
    // Assert each queue
    for (const queue of queues) {
      await channel.assertQueue(queue, { durable: true });
    }
    
    // Define exchanges
    const exchanges = [
      { name: 'appointments', type: 'topic' },
      { name: 'logs', type: 'topic' }
    ];
    
    // Assert each exchange
    for (const exchange of exchanges) {
      await channel.assertExchange(exchange.name, exchange.type, { durable: true });
    }
    
    // Bind queues to exchanges
    await channel.bindQueue('system-logs', 'logs', 'appointment.*');
    await channel.bindQueue('appointment-created', 'appointments', 'appointment.created');
    await channel.bindQueue('appointment-updated', 'appointments', 'appointment.updated');
    await channel.bindQueue('appointment-cancelled', 'appointments', 'appointment.cancelled');
    
    logger.info('✅ Connected to RabbitMQ');
    return { channel, connection };
  } catch (error) {
    logger.error('❌ RabbitMQ connection error:', error.message);
    throw error;
  }
}

async function sendMessage(queueName, message) {
  try {
    if (!channel) await connectRabbitMQ();
    
    return channel.sendToQueue(
      queueName, 
      Buffer.from(JSON.stringify(message)), 
      { persistent: true }
    );
  } catch (error) {
    logger.error(`Failed to send message to queue ${queueName}:`, error);
    throw error;
  }
}

async function consumeMessage(queueName, callback) {
  try {
    if (!channel) await connectRabbitMQ();
    
    return channel.consume(queueName, (msg) => {
      if (msg !== null) {
        try {
          const content = JSON.parse(msg.content.toString());
          callback(content);
          channel.ack(msg);
        } catch (error) {
          logger.error(`Error processing message from ${queueName}:`, error);
          // Negative acknowledge with requeue
          channel.nack(msg, false, true);
        }
      }
    });
  } catch (error) {
    logger.error(`Failed to consume messages from queue ${queueName}:`, error);
    throw error;
  }
}

async function publishToExchange(exchange, routingKey, message) {
  try {
    if (!channel) await connectRabbitMQ();
    
    return channel.publish(
      exchange,
      routingKey,
      Buffer.from(JSON.stringify(message)),
      { persistent: true }
    );
  } catch (error) {
    logger.error(`Failed to publish message to exchange ${exchange}:`, error);
    throw error;
  }
}

async function closeConnection() {
  try {
    if (channel) await channel.close();
    if (connection) await connection.close();
    logger.info('RabbitMQ connection closed');
  } catch (error) {
    logger.error('Error closing RabbitMQ connection:', error);
  }
}

// Add a graceful shutdown handler
process.on('SIGINT', async () => {
  logger.info('Closing RabbitMQ connections...');
  await closeConnection();
  process.exit(0);
});

module.exports = {
  connectRabbitMQ,
  sendMessage,
  consumeMessage,
  publishToExchange,
  closeConnection,
  // FIXED: Make sure these legacy methods are available
  sendToService: sendMessage, // Alias for backward compatibility
  publish: publishToExchange   // Alias for backward compatibility
};