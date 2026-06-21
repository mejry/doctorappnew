const mongoose = require('mongoose');
require('dotenv').config({ path: 'src/config/.env' });

const connectDB = async () => {
  try {
    console.log('entered db');
    await mongoose.connect(process.env.DB_CONNECTION_STRING, {
      useNewUrlParser: true,
      useUnifiedTopology: true
    });
    console.log('✅ MongoDB connected successfully');
  } catch (err) {
    console.log(err);

    console.error('❌ MongoDB connection error:', err.message);
    process.exit(1);
  }
};

mongoose.set('strictQuery', true);
module.exports = connectDB;