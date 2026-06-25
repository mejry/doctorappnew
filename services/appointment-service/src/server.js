// appointment-service/src/server.js
const express = require('express');

const cron = require('node-cron');
const config = require('./config/config');
const logger = require('./config/logger');
const { connectDB, disconnectDB } = require('./config/db');
const rabbitmq = require('./config/rabbitmq');
const appointmentRoutes = require('./routes/appointmentRoutes');
const appointmentService = require('./services/appointmentService');
const { startAuthConsumer } = require('./services/authConsumer');
const waitingRoomRoutes = require('./routes/waitingRoomRoutes');
// Initialize Express app
const app = express();

// Middleware
// CORS handled by gateway
app.use(express.json());

// Request logging middleware
app.use((req, res, next) => {
  logger.info(`${req.method} ${req.url}`);
  
  // Log request headers for debugging token issues
  if (req.headers.authorization) {
    console.log('Authorization header found:', req.headers.authorization.substring(0, 20) + '...');
  } else {
    console.log('No authorization header found');
  }
  
  next();
});

// Connect to services first to ensure they're ready before accepting requests
async function initializeServices() {
  try {
    // Connect to MongoDB
    console.log('Connecting to MongoDB...');
    await connectDB();
    
    // Connect to RabbitMQ and start consumers disabled to keep console clean for the user
    /*
    console.log('Connecting to RabbitMQ...');
    await rabbitmq.connect();
    
    // Start auth consumer to listen for token updates
    console.log('Starting auth consumer...');
    await startAuthConsumer().catch(err => {
      console.error('Failed to start auth consumer:', err);
      // Don't exit, just log the error
    });
    */
    
    console.log('All services connected successfully');
    return true;
  } catch (error) {
    console.error('Failed to initialize services:', error);
    return false;
  }
}

// Routes
app.use('/api/appointments', appointmentRoutes);
app.use('/api/waiting-room', waitingRoomRoutes);

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    service: 'appointment-service',
    status: 'healthy',
    timestamp: new Date()
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  logger.error('Unhandled error:', err);
  
  res.status(500).json({
    success: false,
    message: 'Internal server error',
    error: config.env === 'development' ? err.message : undefined
  });
});

// Start the server
async function startServer() {
  try {
    // Initialize services first
    const servicesReady = await initializeServices();

    if (!servicesReady) {
      logger.warn('Some auxiliary services (MongoDB/RabbitMQ) failed to initialize — starting server anyway. Some features may be limited.');
      // Continue startup even if optional services failed
    }
    
    // Schedule appointment reminders using cron
    cron.schedule(config.reminderCron, async () => {
      logger.info('Running appointment reminder scheduler');
      try {
        const result = await appointmentService.scheduleReminders();
        logger.info(`Scheduled ${result.sent} appointment reminders`);
      } catch (error) {
        logger.error('Error scheduling reminders:', error);
      }
    });
    
    // Start server
    const server = app.listen(config.port, '0.0.0.0', () => {
      logger.info(`Appointment service running on port ${config.port}`);
    });
    
    // Graceful shutdown
    const gracefulShutdown = async () => {
      logger.info('Received shutdown signal, closing connections...');
      
      // Close server
      server.close(() => {
        logger.info('HTTP server closed');
      });
      
      // Close RabbitMQ connection
      await rabbitmq.close();
      
      // Close MongoDB connection
      await disconnectDB();
      
      process.exit(0);
    };
    
    // Listen for termination signals
    process.on('SIGTERM', gracefulShutdown);
    process.on('SIGINT', gracefulShutdown);
    
  } catch (error) {
    logger.error('Failed to start server:', error);
    process.exit(1);
  }
}

// Start the server
startServer();

// For testing
module.exports = app;