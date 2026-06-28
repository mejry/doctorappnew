const dotenv = require("dotenv");

const path = require("path");
const mongoose = require("mongoose");
dotenv.config({ path: path.resolve(__dirname, "../../.env") });

const connectDB = async () => {
  try {
    const mongoUri =
      process.env.MONGO_URI ||
      process.env.MONGODB_URI ||
      process.env.DB_CONNECTION_STRING ||
      "mongodb://127.0.0.1:27017/patient-service";
    await mongoose.connect(mongoUri, { serverSelectionTimeoutMS: 5000 });
    console.log(" MongoDB connected successfully");
  } catch (err) {
    console.error(" MongoDB connection error:", err.message);
    process.exit(1);
  }
};

mongoose.set("strictQuery", true);
module.exports = connectDB;
