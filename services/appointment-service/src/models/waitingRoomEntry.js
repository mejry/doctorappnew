// appointment-service/src/models/waitingRoomEntry.js
const mongoose = require('mongoose');

const WaitingRoomEntrySchema = new mongoose.Schema({
  appointmentId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Appointment',
    required: true,
    unique: true
  },
  doctorId: {
    type: String,
    required: true,
    index: true
  },
  patientName: {
    type: String,
    required: true
  },
  date: {
    type: Date,
    required: true,
    index: true
  },
  scheduledTime: {
    type: String,
    required: true
  },
  status: {
    type: String,
    enum: ['Waiting', 'Checked-in', 'In-progress', 'Completed', 'No-show', 'Cancelled'],
    default: 'Waiting',
    index: true
  },
  priority: {
    type: String,
    enum: ['Low', 'Normal', 'High', 'Emergency'],
    default: 'Normal'
  },
  priorityReason: {
    type: String
  },
  checkedInAt: {
    type: Date
  },
  consultationStartedAt: {
    type: Date
  },
  consultationCompletedAt: {
    type: Date
  },
  actualConsultationDuration: {
    type: Number // in minutes
  },
  notes: {
    type: String
  },
  noShowReason: {
    type: String
  },
  // AI estimation data
  aiEstimatedDuration: {
    type: Number
  },
  aiConfidenceScore: {
    type: Number
  },
  aiLastUpdated: {
    type: Date
  },
  // Tracking who performed actions
  checkedInBy: {
    type: String
  },
  consultationStartedBy: {
    type: String
  },
  consultationCompletedBy: {
    type: String
  },
  markedNoShowBy: {
    type: String
  }
}, { 
  timestamps: true,
  toJSON: { virtuals: true }
});

// Indexes for efficient queries
WaitingRoomEntrySchema.index({ doctorId: 1, date: 1, status: 1 });
WaitingRoomEntrySchema.index({ appointmentId: 1 });
WaitingRoomEntrySchema.index({ date: 1, scheduledTime: 1 });
WaitingRoomEntrySchema.index({ status: 1, priority: -1 });

// Virtual for total time in waiting room
WaitingRoomEntrySchema.virtual('totalWaitingTime').get(function() {
  if (this.checkedInAt && this.consultationStartedAt) {
    return Math.floor((this.consultationStartedAt - this.checkedInAt) / (1000 * 60));
  }
  return null;
});

module.exports = mongoose.model('WaitingRoomEntry', WaitingRoomEntrySchema);