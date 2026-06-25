// auth-service/src/server.js
const fs = require('fs');
const path = require('path');
process.on('uncaughtException', (err) => {
  fs.writeFileSync(path.join(__dirname, '../CRASH_LOG.txt'), err.stack || err.message);
  process.exit(1);
});
process.on('unhandledRejection', (reason) => {
  fs.writeFileSync(path.join(__dirname, '../REJECTION_LOG.txt'), String(reason));
});

require("dotenv").config({ path: "./.env" });
const express = require("express");
const cookieParser = require("cookie-parser");
const morgan = require("morgan");

const connectDB = require("./config/db");
const rateLimit = require("express-rate-limit");
const logConsumer = require("./services/logConsumer");
const userRoutes = require("./routes/userRoutes");

// Default environment variables if not set
require("dotenv").config({ path: "./.env" });
process.env.PORT = process.env.PORT || "4000";
//process.env.JWT_SECRET = process.env.JWT_SECRET || 'azertyuiophgfdsdfghjk745120';
process.env.JWT_SECRET = process.env.JWT_SECRET || "jhfduzeajhdsqygiaz";

// Create Express app
const app = express();

// CORS handled by API Gateway

// Body parser
app.use(express.json());

// Cookie parser
app.use(cookieParser());

// Request logging
app.use(morgan("dev"));

// Rate limiting for auth endpoints
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limit each IP to 100 requests per window
  message: "Too many requests from this IP, please try again later",
});

// Database connection
connectDB().catch((err) => {
  console.error("Database connection error:", err);
  process.exit(1);
});

// Start log consumer (DISABLED FOR NOW TO AVOID CONSOLE ERRORS)
// logConsumer.start().catch((err) => {
//   console.error("Failed to start log consumer:", err);
//   // Don't exit - service can still function without log consumer
// });

// Routes
const authRoutes = require("./routes/authRoutes");
const adminLogRoutes = require("./routes/adminLogRoutes");

app.use("/api/auth", authLimiter, authRoutes);
app.use("/api/logs", adminLogRoutes);
app.use("/api/users", userRoutes);

// Health check endpoint
app.get("/health", (req, res) => {
  res.status(200).json({
    status: "success",
    message: "Auth service is up and running",
    timestamp: new Date().toISOString(),
  });
});
// Error handling middleware
app.use((err, req, res, next) => {
  console.error("Error:", err);

  res.status(err.statusCode || 500).json({
    error:
      process.env.NODE_ENV === "production"
        ? "Internal server error"
        : err.message,
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: "Endpoint not found" });
});

// Start server
const PORT = 4000;
app.listen(PORT, () => {
  console.log(`✅ Auth service running on port ${PORT}`);
});
