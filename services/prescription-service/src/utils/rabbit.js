const amqp = require('amqplib');
const { v4: uuidv4 } = require('uuid');

let channel, connection;

async function connectRabbitMQ() {
  try {
    connection = await amqp.connect(process.env.RABBITMQ_URL);
    channel = await connection.createChannel();
    
    await channel.assertExchange('medical_events', 'topic', { durable: true });
    console.log('✅ RabbitMQ connected for Prescription Service');
    
    connection.on('close', () => {
      setTimeout(connectRabbitMQ, 5000);
    });

    return { channel, connection };
  } catch (error) {
    console.error('RabbitMQ connection failed:', error);
    throw error;
  }
}

async function publishEvent(eventType, routingKey, data) {
  try {
    if (!channel) {
      console.warn(`⚠️ RabbitMQ not connected. Skipping event: ${eventType}`);
      return;
    }
    
    const message = {
      eventId: uuidv4(),
      eventType,
      timestamp: new Date(),
      data
    };

    channel.publish(
      'medical_events',
      routingKey,
      Buffer.from(JSON.stringify(message)),
      { persistent: true }
    );
  } catch (error) {
    console.warn(`⚠️ Failed to publish event ${eventType}, but continuing without it.`);
  }
}

async function consumeEvents(queue, routingKey, callback) {
  if (!channel) await connectRabbitMQ();
  
  const q = await channel.assertQueue(queue, { durable: true });
  await channel.bindQueue(q.queue, 'medical_events', routingKey);
  
  channel.consume(q.queue, async (msg) => {
    const event = JSON.parse(msg.content.toString());
    try {
      await callback(event);
      channel.ack(msg);
    } catch (error) {
      console.error('Error processing event:', error);
      channel.nack(msg, false, false);
    }
  });
}

module.exports = {
  connectRabbitMQ,
  publishEvent,
  consumeEvents
};