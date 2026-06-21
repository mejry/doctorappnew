// appointment-service/src/config/config.js
require('dotenv').config();

module.exports = {
  env: process.env.NODE_ENV || 'development',
  port: process.env.PORT || 3001,
  
  mongo: {
    url: process.env.MONGODB_URI || 'mongodb://localhost:27017/appointment-service',
    options: {
      useNewUrlParser: true,
      useUnifiedTopology: true
    }
  },
  
  rabbitmq: {
    url: process.env.RABBITMQ_URL || 'amqp://localhost',
    queues: {
      authTokens: 'auth-tokens',
      appointmentCreated: 'appointment-created',
      appointmentUpdated: 'appointment-updated',
      appointmentCancelled: 'appointment-cancelled'
    },
    exchangeName: 'appointments'
  },
  
  jwt: {
    serviceSecret: process.env.JWT_SERVICE_SECRET || 'jhfduzeajhdsqygiaz',
    algorithm: 'HS256',
    expiresIn: '1h'
  },
  
  email: {
    service: process.env.EMAIL_SERVICE || 'gmail',
    auth: {
      user: process.env.EMAIL_USER || '',
      pass: process.env.EMAIL_PASSWORD || ''
    },
    enabled: !!process.env.EMAIL_USER
  },
  
  logs: {
    level: process.env.LOG_LEVEL || 'info'
  },
  ai: {
    serviceUrl: process.env.AI_SERVICE_URL || 'http://localhost:5001',
    timeout: process.env.AI_TIMEOUT || 5000,
    enabled: process.env.AI_ENABLED !== 'false'
  },

  
  // Daily cron job for appointment reminders (default: 8:00 AM)
  reminderCron: process.env.REMINDER_CRON || '0 9 * * *',
  reminderHours: process.env.REMINDER_HOURS || 24,
  maxAppointmentsPerDay: process.env.MAX_APPOINTMENTS_PER_DAY || 30
};