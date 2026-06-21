require('dotenv').config();

module.exports = {
  env: process.env.NODE_ENV || 'development',
  port: process.env.PORT || 8002,
  rabbitmq: {
    url: process.env.RABBITMQ_URL || 'amqp://localhost',
    queues: {
      authTokens: 'auth-tokens',
      patientEvents: 'patient-events'
    },
    exchangeName: 'patients'
  },
  
jwt: {
  serviceSecret: process.env.JWT_SERVICE_SECRET || 'jhfduzeajhdsqygiaz',
  accessSecret: process.env.JWT_ACCESS_SECRET || 'azerdqskfuiqaqlkeza', 
  refreshSecret: process.env.JWT_REFRESH_SECRET || 'aeziugizfodabnzeyiad',
  algorithm: 'HS256',
  expiresIn: '1h'
},
  
  // Autres configurations spécifiques au patient service
  patient: {
    maxMedicalHistoryEntries: process.env.MAX_MEDICAL_HISTORY_ENTRIES || 100,
    dataRetentionDays: process.env.DATA_RETENTION_DAYS || 365
  }
};