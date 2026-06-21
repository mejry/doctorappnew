// auth-service/src/models/LogEntry.js
const mongoose = require('mongoose');

/**
 * Extended Log Entry model for centralized logging
 * Used by the log consumer to store logs from all services
 */
const logEntrySchema = new mongoose.Schema({
  // When the event occurred
  timestamp: { 
    type: Date, 
    default: Date.now, 
    index: true 
  },
  
  // Type of event (e.g., APPOINTMENT_CREATED, APPOINTMENT_CANCELLED)
  eventType: { 
    type: String,
    required: true,
    index: true
  },
  
  // Action performed (e.g., create, update, cancel, view)
   action: {
    type: String,
    required: true
  },
  // Type of resource (e.g., appointment, user, role)
  resourceType: {
    type: String,
    index: true
  },
  
  // ID of the resource (e.g., appointment ID)
  resourceId: {
    type: mongoose.Schema.Types.ObjectId,
    index: true
  },
  
  // User who performed the action
  userId: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'User',
    index: true
  },
  
  // Target user (if applicable)
  targetId: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'User' 
  },
  
  // Additional details about the action (stored as JSON)
  details: mongoose.Schema.Types.Mixed,
  
  // Human-readable message
  message: String,
  
  // IP address of the client
  ipAddress: String,
  
  // User agent of the client
  userAgent: String,
  
  // Additional metadata
  metadata: mongoose.Schema.Types.Mixed
}, { 
  timestamps: true // Adds createdAt and updatedAt fields
});

// Create text index for searching message content
logEntrySchema.index({ message: 'text' });

// Create compound indexes for common queries
logEntrySchema.index({ userId: 1, timestamp: -1 });
logEntrySchema.index({ resourceType: 1, resourceId: 1 });
logEntrySchema.index({ eventType: 1, timestamp: -1 });

/**
 * Format the timestamp to a readable string
 */
logEntrySchema.methods.formattedTimestamp = function() {
  return this.timestamp.toISOString();
};

/**
 * Get a simplified representation for summary views
 */
logEntrySchema.methods.getSummary = function() {
  return {
    id: this._id,
    timestamp: this.formattedTimestamp(),
    eventType: this.eventType,
    action: this.action,
    resourceType: this.resourceType,
    message: this.message,
    userId: this.userId
  };
};

module.exports = mongoose.model('LogEntry', logEntrySchema);