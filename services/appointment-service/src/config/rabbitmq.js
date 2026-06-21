// appointment-service/src/config/rabbitmq.js
const amqp = require('amqplib');
const config = require('./config');
const logger = require('./logger');

const QUEUES = config.rabbitmq.queues;

let channel = null;
let connection = null;
let isConnected = false;
let connectionPromise = null;

function isConnectedToRabbitMQ() {
  return isConnected && channel && connection;
}

async function connect() {
  if (isConnectedToRabbitMQ()) return;

  if (connectionPromise) {
    return connectionPromise;
  }

  connectionPromise = _connect();

  try {
    await connectionPromise;
  } finally {
    connectionPromise = null;
  }
}

async function _connect(retries = 5, delay = 4000) {
  let attempt = 0;

  while (attempt <= retries) {
    try {
      connection = await amqp.connect(config.rabbitmq.url);

      connection.on('error', (err) => {
        logger.error(`RabbitMQ connection error: ${err.message}`);
        isConnected = false;
      });

      connection.on('close', () => {
        logger.warn('RabbitMQ connection closed');
        isConnected = false;
        channel = null;
        connection = null;

        setTimeout(() => {
          logger.info('Attempting to reconnect to RabbitMQ...');
          connect().catch((err) => {
            logger.error(`Failed to reconnect to RabbitMQ: ${err.message}`);
          });
        }, delay);
      });

      channel = await connection.createChannel();

      await channel.assertExchange(config.rabbitmq.exchangeName, 'topic', {
        durable: true,
      });

      await channel.assertQueue(QUEUES.authTokens, { durable: true });
      await channel.assertQueue(QUEUES.appointmentCreated, { durable: true });
      await channel.assertQueue(QUEUES.appointmentUpdated, { durable: true });
      await channel.assertQueue(QUEUES.appointmentCancelled, { durable: true });

      // Prevent consuming too many messages at once
      channel.prefetch(1);

      isConnected = true;
      logger.info('✅ Connected to RabbitMQ');

      return true;
    } catch (error) {
      attempt++;

      isConnected = false;
      channel = null;
      connection = null;

      if (attempt > retries) {
        logger.error(
          `❌ Failed to connect to RabbitMQ after multiple attempts: ${error.message}`
        );
        throw error;
      }

      logger.warn(
        `RabbitMQ connection attempt ${attempt} failed. Retrying in ${delay}ms...`
      );

      await new Promise((resolve) => setTimeout(resolve, delay));
    }
  }
}

async function publish(queue, message) {
  if (!isConnectedToRabbitMQ()) {
    await connect();
  }

  try {
    return channel.sendToQueue(queue, Buffer.from(JSON.stringify(message)), {
      persistent: true,
    });
  } catch (error) {
    logger.error(`Error publishing to queue ${queue}: ${error.message}`);

    isConnected = false;
    await connect();

    return channel.sendToQueue(queue, Buffer.from(JSON.stringify(message)), {
      persistent: true,
    });
  }
}

async function publishToExchange(routingKey, message) {
  if (!isConnectedToRabbitMQ()) {
    await connect();
  }

  try {
    return channel.publish(
      config.rabbitmq.exchangeName,
      routingKey,
      Buffer.from(JSON.stringify(message)),
      { persistent: true }
    );
  } catch (error) {
    logger.error(
      `Error publishing to exchange with routing key ${routingKey}: ${error.message}`
    );

    isConnected = false;
    await connect();

    return channel.publish(
      config.rabbitmq.exchangeName,
      routingKey,
      Buffer.from(JSON.stringify(message)),
      { persistent: true }
    );
  }
}

async function consume(queue, callback) {
  if (!isConnectedToRabbitMQ()) {
    await connect();
  }

  try {
    await channel.assertQueue(queue, { durable: true });
    channel.prefetch(1);

    return channel.consume(queue, async (msg) => {
      if (!msg) return;

      try {
        const content = JSON.parse(msg.content.toString());

        await callback(content);

        channel.ack(msg);
      } catch (error) {
        logger.error(`Error processing message from ${queue}: ${error.message}`);

        // false = do not requeue, avoids infinite loop
        channel.nack(msg, false, false);
      }
    });
  } catch (error) {
    logger.error(`Error setting up consumer for queue ${queue}: ${error.message}`);

    isConnected = false;
    await connect();

    await channel.assertQueue(queue, { durable: true });
    channel.prefetch(1);

    return channel.consume(queue, async (msg) => {
      if (!msg) return;

      try {
        const content = JSON.parse(msg.content.toString());

        await callback(content);

        channel.ack(msg);
      } catch (err) {
        logger.error(`Error processing message from ${queue}: ${err.message}`);

        // false = do not requeue, avoids infinite loop
        channel.nack(msg, false, false);
      }
    });
  }
}

async function close() {
  try {
    if (channel) {
      await channel.close();
    }

    if (connection) {
      await connection.close();
    }
  } catch (error) {
    logger.error(`Error closing RabbitMQ connection: ${error.message}`);
  } finally {
    channel = null;
    connection = null;
    isConnected = false;
  }
}

module.exports = {
  connect,
  publish,
  publishToExchange,
  consume,
  close,
  isConnected: isConnectedToRabbitMQ,
  QUEUES,
};