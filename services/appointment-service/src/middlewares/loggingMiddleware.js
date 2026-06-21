// appointment-service/src/middlewares/loggingMiddleware.js
const logger = require('../config/logger');
const rabbitmq = require('../config/rabbitmq');

/**
 * Middleware for logging appointment service operations
 * To be applied after controller functions have been executed
 */
const loggingMiddleware = {
  /**
   * Log appointment creation
   * @param {Object} req - Express request object
   * @param {Object} res - Express response object
   * @param {Function} next - Express next middleware function
   */
  logAppointmentCreated: (req, res, next) => {
    console.log('Setting up logAppointmentCreated middleware');
    
    // Store the original send method
    const originalSend = res.send;
    
    // Override the send method
    res.send = function(data) {
      try {
        // Parse the response data
        const responseBody = JSON.parse(data);
        
        // If operation was successful, log it
        if (responseBody.success && responseBody.appointment) {
          const appointment = responseBody.appointment;
          const user = req.user || { id: 'unknown', role: 'unknown' };
          
          console.log(`Logging appointment creation: ID ${appointment._id} by user ${user.id} (${user.role}) for patient ${appointment.patientName}`);
          
          // Log to local logs
          logger.info(`Appointment created: ID ${appointment._id} by user ${user.id} (${user.role}) for patient ${appointment.patientName}`);
          
          // Create log message for RabbitMQ
          const logMessage = {
            type: 'APPOINTMENT_CREATED',
            timestamp: new Date(),
            data: {
              appointmentId: appointment._id,
              patientName: appointment.patientName,
              doctorId: appointment.doctorId,
              doctorName: appointment.doctorName,
              date: appointment.date,
              time: appointment.time,
              status: appointment.status
            },
            user: {
              id: user.id,
              role: user.role,
              permissions: user.permissions || []
            },
            context: {
              ipAddress: req.ip || req.headers['x-forwarded-for'] || 'unknown',
              userAgent: req.headers['user-agent'] || 'unknown',
              method: req.method,
              url: req.originalUrl
            }
          };
          
          // Send to RabbitMQ for centralized logging
          rabbitmq.publishToExchange('logs', 'appointment.created', logMessage)
            .then(() => console.log('Successfully published to logs exchange'))
            .catch(error => console.error('Failed to publish log to RabbitMQ:', error));
        } else {
          console.log('Operation was not successful or no appointment data in response');
          if (responseBody.success === false) {
            console.log('Error message:', responseBody.message);
          }
        }
      } catch (error) {
        console.error('Error in logAppointmentCreated middleware:', error);
      }
      
      // Call the original send function
      return originalSend.call(this, data);
    };
    
    next();
  },
  
  /**
   * Log appointment update
   * @param {Object} req - Express request object
   * @param {Object} res - Express response object
   * @param {Function} next - Express next middleware function
   */
  logAppointmentUpdated: (req, res, next) => {
    console.log('Setting up logAppointmentUpdated middleware');
    
    // Store the original send method
    const originalSend = res.send;
    
    // Override the send method
    res.send = function(data) {
      try {
        // Parse the response data
        const responseBody = JSON.parse(data);
        
        // If operation was successful, log it
        if (responseBody.success && responseBody.appointment) {
          const appointment = responseBody.appointment;
          const user = req.user || { id: 'unknown', role: 'unknown' };
          
          console.log(`Logging appointment update: ID ${appointment._id} by user ${user.id} (${user.role}) for patient ${appointment.patientName}`);
          
          // Log to local logs
          logger.info(`Appointment updated: ID ${appointment._id} by user ${user.id} (${user.role}) for patient ${appointment.patientName}`);
          
          // Create log message for RabbitMQ
          const logMessage = {
            type: 'APPOINTMENT_UPDATED',
            timestamp: new Date(),
            data: {
              appointmentId: appointment._id,
              patientName: appointment.patientName,
              doctorId: appointment.doctorId,
              doctorName: appointment.doctorName,
              date: appointment.date,
              time: appointment.time,
              status: appointment.status,
              changes: req.body // What fields were updated
            },
            user: {
              id: user.id,
              role: user.role,
              permissions: user.permissions || []
            },
            context: {
              ipAddress: req.ip || req.headers['x-forwarded-for'] || 'unknown',
              userAgent: req.headers['user-agent'] || 'unknown',
              method: req.method,
              url: req.originalUrl
            }
          };
          
          // Send to RabbitMQ for centralized logging
          rabbitmq.publishToExchange('logs', 'appointment.updated', logMessage)
            .then(() => console.log('Successfully published to logs exchange'))
            .catch(error => console.error('Failed to publish log to RabbitMQ:', error));
        } else {
          console.log('Operation was not successful or no appointment data in response');
          if (responseBody.success === false) {
            console.log('Error message:', responseBody.message);
          }
        }
      } catch (error) {
        console.error('Error in logAppointmentUpdated middleware:', error);
      }
      
      // Call the original send function
      return originalSend.call(this, data);
    };
    
    next();
  },
  
  /**
   * Log appointment cancellation
   * @param {Object} req - Express request object
   * @param {Object} res - Express response object
   * @param {Function} next - Express next middleware function
   */
  logAppointmentCancelled: (req, res, next) => {
    console.log('Setting up logAppointmentCancelled middleware');
    
    // Store the original send method
    const originalSend = res.send;
    
    // Override the send method
    res.send = function(data) {
      try {
        // Parse the response data
        const responseBody = JSON.parse(data);
        
        // If operation was successful, log it
        if (responseBody.success && responseBody.appointment) {
          const appointment = responseBody.appointment;
          const user = req.user || { id: 'unknown', role: 'unknown' };
          
          console.log(`Logging appointment cancellation: ID ${appointment._id} by user ${user.id} (${user.role}) - reason: ${req.body.cancellationReason}`);
          
          // Log to local logs
          logger.info(`Appointment cancelled: ID ${appointment._id} by user ${user.id} (${user.role}) - reason: ${req.body.cancellationReason}`);
          
          // Create log message for RabbitMQ
          const logMessage = {
            type: 'APPOINTMENT_CANCELLED',
            timestamp: new Date(),
            data: {
              appointmentId: appointment._id,
              patientName: appointment.patientName,
              doctorId: appointment.doctorId,
              doctorName: appointment.doctorName,
              date: appointment.date,
              time: appointment.time,
              status: 'Cancelled',
              cancellationReason: req.body.cancellationReason
            },
            user: {
              id: user.id,
              role: user.role,
              permissions: user.permissions || []
            },
            context: {
              ipAddress: req.ip || req.headers['x-forwarded-for'] || 'unknown',
              userAgent: req.headers['user-agent'] || 'unknown',
              method: req.method,
              url: req.originalUrl
            }
          };
          
          // Send to RabbitMQ for centralized logging
          rabbitmq.publishToExchange('logs', 'appointment.cancelled', logMessage)
            .then(() => console.log('Successfully published to logs exchange'))
            .catch(error => console.error('Failed to publish log to RabbitMQ:', error));
        } else {
          console.log('Operation was not successful or no appointment data in response');
          if (responseBody.success === false) {
            console.log('Error message:', responseBody.message);
          }
        }
      } catch (error) {
        console.error('Error in logAppointmentCancelled middleware:', error);
      }
      
      // Call the original send function
      return originalSend.call(this, data);
    };
    
    next();
  },
  
  /**
   * Log appointments retrieved
   * @param {Object} req - Express request object
   * @param {Object} res - Express response object
   * @param {Function} next - Express next middleware function
   */
  logAppointmentsRetrieved: (req, res, next) => {
    console.log('Setting up logAppointmentsRetrieved middleware');
    
    // Store the original send method
    const originalSend = res.send;
    
    // Override the send method
    res.send = function(data) {
      try {
        // Parse the response data
        const responseBody = JSON.parse(data);
        
        // If operation was successful, log it
        if (responseBody.success && responseBody.appointments) {
          const user = req.user || { id: 'unknown', role: 'unknown' };
          
          console.log(`Logging appointments retrieved: ${responseBody.total} appointments by user ${user.id} (${user.role})`);
          
          // Log to local logs
          logger.info(`Appointments retrieved: ${responseBody.total} appointments by user ${user.id} (${user.role})`);
          
          // Create log message for RabbitMQ
          const logMessage = {
            type: 'APPOINTMENTS_VIEWED',
            timestamp: new Date(),
            data: {
              count: responseBody.total,
              filters: req.query
            },
            user: {
              id: user.id,
              role: user.role,
              permissions: user.permissions || []
            },
            context: {
              ipAddress: req.ip || req.headers['x-forwarded-for'] || 'unknown',
              userAgent: req.headers['user-agent'] || 'unknown',
              method: req.method,
              url: req.originalUrl
            }
          };
          
          // Send to RabbitMQ for centralized logging
          rabbitmq.publishToExchange('logs', 'appointment.viewed', logMessage)
            .then(() => console.log('Successfully published to logs exchange'))
            .catch(error => console.error('Failed to publish log to RabbitMQ:', error));
        } else {
          console.log('Operation was not successful or no appointments data in response');
          if (responseBody.success === false) {
            console.log('Error message:', responseBody.message);
          }
        }
      } catch (error) {
        console.error('Error in logAppointmentsRetrieved middleware:', error);
      }
      
      // Call the original send function
      return originalSend.call(this, data);
    };
    
    next();
  },
  
  /**
   * Log appointment found by ID
   * @param {Object} req - Express request object
   * @param {Object} res - Express response object
   * @param {Function} next - Express next middleware function
   */
  logAppointmentRetrieved: (req, res, next) => {
    console.log('Setting up logAppointmentRetrieved middleware');
    
    // Store the original send method
    const originalSend = res.send;
    
    // Override the send method
    res.send = function(data) {
      try {
        // Parse the response data
        const responseBody = JSON.parse(data);
        
        // If operation was successful, log it
        if (responseBody.success && responseBody.appointment) {
          const appointment = responseBody.appointment;
          const user = req.user || { id: 'unknown', role: 'unknown' };
          
          console.log(`Logging appointment retrieved: ID ${appointment._id} by user ${user.id} (${user.role})`);
          
          // Log to local logs
          logger.info(`Appointment retrieved: ID ${appointment._id} by user ${user.id} (${user.role})`);
          
          // Create log message for RabbitMQ
          const logMessage = {
            type: 'APPOINTMENT_VIEWED',
            timestamp: new Date(),
            data: {
              appointmentId: appointment._id,
              patientName: appointment.patientName,
              doctorId: appointment.doctorId,
              doctorName: appointment.doctorName
            },
            user: {
              id: user.id,
              role: user.role,
              permissions: user.permissions || []
            },
            context: {
              ipAddress: req.ip || req.headers['x-forwarded-for'] || 'unknown',
              userAgent: req.headers['user-agent'] || 'unknown',
              method: req.method,
              url: req.originalUrl
            }
          };
          
          // Send to RabbitMQ for centralized logging
          rabbitmq.publishToExchange('logs', 'appointment.viewed', logMessage)
            .then(() => console.log('Successfully published to logs exchange'))
            .catch(error => console.error('Failed to publish log to RabbitMQ:', error));
        } else {
          console.log('Operation was not successful or no appointment data in response');
          if (responseBody.success === false) {
            console.log('Error message:', responseBody.message);
          }
        }
      } catch (error) {
        console.error('Error in logAppointmentRetrieved middleware:', error);
      }
      
      // Call the original send function
      return originalSend.call(this, data);
    };
    
    next();
  },
  
  /**
   * Log appointment reminders sent
   * @param {Object} req - Express request object
   * @param {Object} res - Express response object
   * @param {Function} next - Express next middleware function
   */
  logRemindersSent: (req, res, next) => {
    console.log('Setting up logRemindersSent middleware');
    
    // Store the original send method
    const originalSend = res.send;
    
    // Override the send method
    res.send = function(data) {
      try {
        // Parse the response data
        const responseBody = JSON.parse(data);
        
        // If operation was successful, log it
        if (responseBody.success) {
          const user = req.user || { id: 'unknown', role: 'unknown' };
          
          console.log(`Logging reminders sent: ${responseBody.sent} of ${responseBody.total} successful by user ${user.id} (${user.role})`);
          
          // Log to local logs
          logger.info(`Appointment reminders sent: ${responseBody.sent} of ${responseBody.total} successful by user ${user.id} (${user.role})`);
          
          // Create log message for RabbitMQ
          const logMessage = {
            type: 'APPOINTMENT_REMINDERS',
            timestamp: new Date(),
            data: {
              total: responseBody.total,
              sent: responseBody.sent,
              success: responseBody.sent === responseBody.total
            },
            user: {
              id: user.id,
              role: user.role,
              permissions: user.permissions || []
            },
            context: {
              ipAddress: req.ip || req.headers['x-forwarded-for'] || 'unknown',
              userAgent: req.headers['user-agent'] || 'unknown',
              method: req.method,
              url: req.originalUrl
            }
          };
          
          // Send to RabbitMQ for centralized logging
          rabbitmq.publishToExchange('logs', 'appointment.reminders', logMessage)
            .then(() => console.log('Successfully published to logs exchange'))
            .catch(error => console.error('Failed to publish log to RabbitMQ:', error));
        } else {
          console.log('Operation was not successful');
          if (responseBody.success === false) {
            console.log('Error message:', responseBody.message);
          }
        }
      } catch (error) {
        console.error('Error in logRemindersSent middleware:', error);
      }
      
      // Call the original send function
      return originalSend.call(this, data);
    };
    
    next();
  }
};

module.exports = loggingMiddleware;