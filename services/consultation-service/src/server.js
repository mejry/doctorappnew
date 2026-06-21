const express = require('express');
const dotenv = require('dotenv');
const connectDB = require('./database/database');

const consultationRoutes = require('./routes/consultationRoutes');

const errorHandler = require('./middlewares/errorMiddleware');
const { startPatientConsumer } = require('./events/consumers/patientConsumer');
const { connectRabbitMQ } = require('./utils/rabbit'); 
const startAuthConsumer = require('./events/consumers/authConsumer');


// Load env vars
dotenv.config({ path: './config/.env' });

const app = express();
const PORT = process.env.PORT || 8003; // Changement du port par défaut

// Middleware
app.use(express.json());

// Routes
app.use('/api/consultations', consultationRoutes); // Changement du point de terminaison

// Error handling
app.use(errorHandler);

// Start server
async function startServer() {
  try {
    await connectDB();

    // Start server listening first
    app.listen(PORT, () => {
      console.log(` Consultation Service running on port ${PORT}`);
    });

    // Try to connect to RabbitMQ and start consumers (non-blocking)
    connectRabbitMQ()
      .then(() => console.log('RabbitMQ connected for consultation service'))
      .catch((err) => console.warn('RabbitMQ unavailable, continuing without it:', err.message || err));

    // Start optional consumers (non-fatal, non-blocking)
    if (typeof startAuthConsumer === 'function') {
      Promise.resolve(startAuthConsumer()).catch((err) => console.warn('Auth consumer failed (non-fatal):', err.message || err));
    }
    try {
      startPatientConsumer();
    } catch (err) {
      console.warn('Patient consumer failed (non-fatal):', err.message || err);
    }
  } catch (error) {
    console.error(' Failed to start server:', error);
    process.exit(1);
  }
}

startServer();