// appointment-service/src/models/appointment.js
const mongoose = require('mongoose');

const AppointmentSchema = new mongoose.Schema({
  patientName: {
    type: String,
    required: [true, 'Patient name is required'],
    trim: true,
    index: true
  },
  patientContact: {
    email: {
      type: String,
      trim: true,
      lowercase: true,
      match: [/^\S+@\S+\.\S+$/, 'Please enter a valid email address']
    },
    phone: {
      type: String,
      trim: true
    }
  },
  doctorId: {
    type: String, // Store as string to avoid MongoDB ObjectId dependency
    required: [true, 'Doctor ID is required'],
    index: true
  },
  doctorName: {
    type: String,
    required: [true, 'Doctor name is required'],
    trim: true
  },
  date: {
    type: Date,
    required: [true, 'Appointment date is required'],
    index: true
  },
  time: {
    type: String,
    required: [true, 'Appointment time is required'],
    match: [/^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$/, 'Time format should be HH:MM']
  },
  type: {
    type: String,
    required: [true, 'Appointment type is required'],
    enum: {
      values: ['Consultation', 'Follow-up', 'Emergency', 'Test', 'Procedure'],
      message: '{VALUE} is not a valid appointment type'
    }
  },
  status: {
    type: String,
    enum: {
      values: ['Scheduled', 'Checked-in', 'In-progress', 'Completed', 'Cancelled', 'No-show'],
      message: '{VALUE} is not a valid status'
    },
    default: 'Scheduled',
    index: true
  },
  notes: {
    type: String,
    trim: true
  },
  duration: {
    type: Number,
    min: 5,
    default: 30, // duration in minutes
    required: true
  },
  cancellationReason: {
    type: String,
    trim: true
  },
  cancellationDate: {
    type: Date
  },
  reminderSent: {
    type: Boolean,
    default: false
  },
  // Track who created and last updated the appointment
  createdBy: {
    type: String,
    default: 'system'
  },
  updatedBy: {
    type: String,
    default: 'system'
  }
}, { 
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Add virtual for formatting date in YYYY-MM-DD format
AppointmentSchema.virtual('formattedDate').get(function() {
  return this.date ? this.date.toISOString().split('T')[0] : null;
});

// Text search index
AppointmentSchema.index({ patientName: 'text' });

// Compound indexes for common queries
AppointmentSchema.index({ doctorId: 1, date: 1 });
AppointmentSchema.index({ status: 1, date: 1 });
AppointmentSchema.index({ date: 1, time: 1 });

module.exports = mongoose.model('Appointment', AppointmentSchema);