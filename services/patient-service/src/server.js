const express = require('express');
const dotenv = require('dotenv');
const connectDB = require('./database/database');
const patientRoutes = require('./routes/patientRoutes');
const errorHandler = require('./middlewares/errorMiddleware');
const { connectRabbitMQ } = require('./utils/rabbit');
const startAuthConsumer = require('./events/consumers/authConsumer');


// Load env vars
dotenv.config({ path: './config/.env' });

const app = express();
const PORT = process.env.PORT || 8002;

// Middleware
app.use(express.json());

// Routes
app.use('/api/patients', patientRoutes);

// Error handling
app.use(errorHandler);


// Start server
async function startServer() {
  try {
    await connectDB();
    await connectDB();

    // RabbitMQ and auth consumers disabled to keep console clean for the user
    /*
    connectRabbitMQ()
      .then(() => console.log('RabbitMQ connected for patient service'))
      .catch((err) => {});

    startAuthConsumer().catch((err) => {});
    */

    app.listen(PORT, () => {
      console.log(` Patient Service running on port ${PORT}`);
    });
  } catch (error) {
    console.error(' Failed to start server:', error);
    process.exit(1);
  }
}

startServer();