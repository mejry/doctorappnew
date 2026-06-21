const dotenv = require('dotenv');

const mongoose = require('mongoose');
dotenv.config({ path: 'src/config/.env' });

const connectDB = async () => {
  try {
    await mongoose.connect(process.env.DB_CONNECTION_STRING);
    console.log(' MongoDB connected successfully');
  } catch (err) {
    console.error(' MongoDB connection error:', err.message);
    process.exit(1);
  }
};

mongoose.set('strictQuery', true);
module.exports = connectDB;