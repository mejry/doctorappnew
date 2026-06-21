// config/config.js
require('dotenv').config();

module.exports = {
  env: process.env.NODE_ENV || 'development',
  port: process.env.PORT || 8004,
  rabbitmq: {
    url: process.env.RABBITMQ_URL || 'amqp://localhost',
    queues: {
      authTokens: 'auth-tokens',
      prescriptionEvents: 'prescription-events',
      patientEvents: 'patient-events',
      consultationEvents: 'consultation-events'
    },
    exchangeName: 'prescriptions'
  },
  
  jwt: {
    serviceSecret: process.env.JWT_SERVICE_SECRET || 'jhfduzeajhdsqygiaz',
    accessSecret: process.env.JWT_ACCESS_SECRET || 'azerdqskfuiqaqlkeza', 
    refreshSecret: process.env.JWT_REFRESH_SECRET || 'aeziugizfodabnzeyiad',
    algorithm: 'HS256',
    expiresIn: '1h'
  },
  
  // Configurations spécifiques au prescription service
  prescription: {
    maxNotesLength: process.env.MAX_NOTES_LENGTH || 1000,
    dataRetentionDays: process.env.DATA_RETENTION_DAYS || 365,
    allowedFileTypes: ['pdf'],
    pdfStoragePath: process.env.PDF_STORAGE_PATH || 'src/storage/prescription'
  },

  // Configuration email
  email: {
    username: process.env.EMAIL_USERNAME,
    password: process.env.EMAIL_PASSWORD,
    from: process.env.EMAIL_FROM
  }
};