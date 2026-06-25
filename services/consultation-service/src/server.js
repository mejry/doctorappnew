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
    app.listen(PORT, '0.0.0.0', () => {
      console.log(` Consultation Service running on port ${PORT}`);
    });

    // Consumers disabled to avoid console spam for the user
    /*
    connectRabbitMQ()
      .then(() => console.log('RabbitMQ connected for consultation service'))
      .catch((err) => {});

    if (typeof startAuthConsumer === 'function') {
      Promise.resolve(startAuthConsumer()).catch((err) => {});
    }
    try {
      startPatientConsumer();
    } catch (err) {}
    */
  } catch (error) {
    console.error(' Failed to start server:', error);
    process.exit(1);
  }
}

startServer();