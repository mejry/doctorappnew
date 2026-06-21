// auth-service/src/services/logConsumer.js
// Import a simple console logger until your actual logger is properly set up
const logger = {
    info: (message, ...args) => console.log(`[INFO] ${message}`, ...args),
    warn: (message, ...args) => console.log(`[WARN] ${message}`, ...args),
    error: (message, ...args) => console.error(`[ERROR] ${message}`, ...args),
    debug: (message, ...args) => console.log(`[DEBUG] ${message}`, ...args)
  };
  
  const rabbitmq = require('../utils/rabbitmq');
  const LogEntry = require('../models/LogEntry');
  
  class LogConsumer {
    constructor() {
      this.isRunning = false;
    }
    
    /**
     * Start consuming logs from RabbitMQ
     */
    async start() {
      if (this.isRunning) {
        logger.warn('Log consumer is already running');
        return;
      }
      
      try {
        // Connect to RabbitMQ if not already connected
        await rabbitmq.connectRabbitMQ();
        
        // Start consuming logs
        await rabbitmq.consumeMessage('system-logs', this.processLogMessage.bind(this));
        
        this.isRunning = true;
        logger.info('✅ Log consumer started');
      } catch (error) {
        logger.error('❌ Failed to start log consumer:', error);
        throw error;
      }
    }
    
    /**
     * Process a log message from RabbitMQ
     * @param {Object} message - The log message
     */
    async processLogMessage(message) {
      try {
        // Extract message data
        const { type, timestamp, data, user, context } = message;
        
        // Skip messages without required fields
        if (!type || !timestamp || !data) {
          logger.warn('Invalid log message received:', message);
          return;
        }
        
        // Create a new log entry
        const logEntry = new LogEntry({
          timestamp: new Date(timestamp),
          eventType: type,
          action: this.extractAction(type),
          resourceType: this.extractResourceType(type, data),
          resourceId: data.appointmentId,
          userId: user?.id,
          details: data,
          message: this.generateLogMessage(type, data),
          ipAddress: context?.ipAddress,
          userAgent: context?.userAgent,
          metadata: {
            userRole: user?.role,
            originalType: type
          }
        });
        
        // Save to database
        await logEntry.save();
        
        logger.debug(`Log entry saved: ${type}`);
      } catch (error) {
        logger.error('Error processing log message:', error);
      }
    }
    
    /**
     * Extract the action from the event type
     * @param {String} type - Event type
     * @returns {String} - Action
     */
    extractAction(type) {
      const actionMap = {
        'APPOINTMENT_CREATED': 'create',
        'APPOINTMENT_UPDATED': 'update',
        'APPOINTMENT_CANCELLED': 'cancel',
        'APPOINTMENT_VIEWED': 'view',
        'APPOINTMENTS_VIEWED': 'list',
        'APPOINTMENT_STATUS_CHANGED': 'status_change',
        'APPOINTMENT_REMINDERS': 'send_reminder'
      };
      
      return actionMap[type] || 'unknown';
    }
    
    /**
     * Extract the resource type from the event type and data
     * @param {String} type - Event type
     * @param {Object} data - Event data
     * @returns {String} - Resource type
     */
    extractResourceType(type, data) {
      if (type.includes('APPOINTMENT')) {
        return 'appointment';
      }
      
      return 'unknown';
    }
    
    /**
     * Generate a human-readable log message
     * @param {String} type - Event type
     * @param {Object} data - Event data
     * @returns {String} - Log message
     */
    generateLogMessage(type, data) {
      switch (type) {
        case 'APPOINTMENT_CREATED':
          return `Appointment created for patient ${data.patientName} with Dr. ${data.doctorName} on ${new Date(data.date).toLocaleDateString()} at ${data.time}`;
        
        case 'APPOINTMENT_UPDATED':
          return `Appointment updated for patient ${data.patientName} with Dr. ${data.doctorName} on ${new Date(data.date).toLocaleDateString()} at ${data.time}`;
        
        case 'APPOINTMENT_CANCELLED':
          return `Appointment cancelled for patient ${data.patientName} with Dr. ${data.doctorName}. Reason: ${data.cancellationReason}`;
        
        case 'APPOINTMENT_VIEWED':
          return `Appointment details viewed for patient ${data.patientName} with Dr. ${data.doctorName}`;
        
        case 'APPOINTMENTS_VIEWED':
          return `${data.count} appointments retrieved`;
        
        case 'APPOINTMENT_STATUS_CHANGED':
          return `Appointment status changed from ${data.oldStatus} to ${data.newStatus} for patient ${data.patientName}`;
        
        case 'APPOINTMENT_REMINDERS':
          return `${data.sent} of ${data.total} appointment reminders sent successfully`;
        
        default:
          return `Unknown log event: ${type}`;
      }
    }
  }
  
  // Export a singleton instance
  module.exports = new LogConsumer();