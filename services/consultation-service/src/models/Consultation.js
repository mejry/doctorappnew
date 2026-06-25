const mongoose = require('mongoose');

const ConsultationSchema = new mongoose.Schema({
  patientId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Patient',
    required: false
  },
  patientName: {
    type: String,
    required: false
  },
  date: {
    type: Date,
    required: true
  },
  time: {
    type: String,
    required: true
  },
  type: {
    type: String,
    required: true,
    enum: ['Bilan', 'Test', 'Consultation', 'Control', 'Follow-up', 'Emergency']
  },
  status: {
    type: String,
    required: true,
    enum: ['Scheduled', 'Completed', 'Canceled', 'Waiting', 'InProgress'],
    default: 'Scheduled'
  },
  symptoms: {
    type: [String],
    default: []
  },
  diagnosis: {
    type: [String],
    default: []
  },
  prescribedAnalyses: {
    type: [String]
  },
  notes: {
    type: String
  },
  duration: {
    type: Number,
  
  },
  isEmergency: {
    type: Boolean,
    default: false
  },
  medicalHistoryId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'MedicalHistory'
  }
}, { timestamps: true });

module.exports = mongoose.model('Consultation', ConsultationSchema);