// config/config.js
require('dotenv').config();

module.exports = {
  env: process.env.NODE_ENV || 'development',
  port: process.env.PORT || 8003, // Port différent pour consultation service
  rabbitmq: {
    url: process.env.RABBITMQ_URL || 'amqp://localhost',
    queues: {
      authTokens: 'auth-tokens',
      consultationEvents: 'consultation-events',
      patientEvents: 'patient-events'
    },
    exchangeName: 'consultations'
  },
  
jwt: {
  serviceSecret: process.env.JWT_SERVICE_SECRET || 'jhfduzeajhdsqygiaz',
  accessSecret: process.env.JWT_ACCESS_SECRET || 'azerdqskfuiqaqlkeza', 
  refreshSecret: process.env.JWT_REFRESH_SECRET || 'aeziugizfodabnzeyiad',
  algorithm: 'HS256',
  expiresIn: '1h'
},
  
  // Configurations spécifiques au consultation service
  consultation: {
    maxNotesLength: process.env.MAX_NOTES_LENGTH || 2000,
    dataRetentionDays: process.env.DATA_RETENTION_DAYS || 365,
    allowedFileTypes: ['pdf', 'jpg', 'png', 'doc', 'docx']
  }
};