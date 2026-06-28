const path = require("path");
const express = require("express");
const dotenv = require("dotenv");
const connectDB = require("./database/database");

const prescriptionRoutes = require("./routes/prescriptionRoutes");
const medicationRoutes = require("./routes/medicationRoutes");
const errorHandler = require("./middlewares/errorMiddleware");
const { connectRabbitMQ } = require("./utils/rabbit");

const initPrescriptionConsumers = require("./events/consumers/prescriptionConsumer");
const startAuthConsumer = require("./events/consumers/authConsumer");

dotenv.config({ path: path.resolve(__dirname, "../.env") });

const app = express();
const PORT = process.env.PORT || 8004;

// Middleware
app.use(express.json());
app.use("/api/medications", medicationRoutes);
// Routes
app.use("/api/prescriptions", prescriptionRoutes);
app.use(
  "/prescriptions",
  express.static(path.join(__dirname, "storage/prescription")),
);

// Error handling
app.use(errorHandler);

async function startServer() {
  try {
    console.log("Connecting to databases...");
    await connectDB();

    // Start server listening first
    app.listen(PORT, () => {
      console.log(`Prescription Service running on port ${PORT}`);
    });

    // Consumers disabled to avoid console spam for the user
    /*
    connectRabbitMQ()
      .then(() => console.log('RabbitMQ connected for prescription service'))
      .catch((err) => {});

    Promise.resolve(startAuthConsumer()).catch((err) => {});
    Promise.resolve(initPrescriptionConsumers()).catch((err) => {});
    */
  } catch (error) {
    console.error("Failed to start server:", error);
    process.exit(1);
  }
}

startServer();
