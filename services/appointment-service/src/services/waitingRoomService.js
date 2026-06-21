// appointment-service/src/services/waitingRoomService.js
const WaitingRoomEntry = require('../models/waitingRoomEntry');
const Appointment = require('../models/appointment');
const logger = require('../config/logger');
const rabbitmq = require('../config/rabbitmq');
const notificationService = require('./notificationService');

class WaitingRoomService {
  
  /**
   * Get today's waiting room queue for a doctor
   */
  async getTodaysQueue(doctorId) {
    try {
      const today = new Date();
      const startOfDay = new Date(today.setHours(0, 0, 0, 0));
      const endOfDay = new Date(today.setHours(23, 59, 59, 999));
      
      const queue = await WaitingRoomEntry.find({
        doctorId: doctorId,
        date: { $gte: startOfDay, $lte: endOfDay },
        status: { $nin: ['Completed', 'Cancelled'] }
      })
      .populate('appointmentId', 'patientName type time duration patientContact')
      .sort({ 
        priority: -1, // Emergency first (High=3, Normal=2, Low=1)
        scheduledTime: 1 // Then by scheduled time
      });
      
      // Organize by status for better UI
      const organized = {
        emergency: queue.filter(entry => entry.priority === 'Emergency'),
        inProgress: queue.filter(entry => entry.status === 'In-progress'),
        checkedIn: queue.filter(entry => entry.status === 'Checked-in'),
        waiting: queue.filter(entry => entry.status === 'Waiting'),
        noShow: queue.filter(entry => entry.status === 'No-show')
      };
      
      return {
        success: true,
        queue: queue,
        organized: organized,
        summary: {
          total: queue.length,
          emergency: organized.emergency.length,
          inProgress: organized.inProgress.length,
          checkedIn: organized.checkedIn.length,
          waiting: organized.waiting.length,
          noShow: organized.noShow.length
        }
      };
      
    } catch (error) {
      logger.error('Error getting today\'s queue:', error);
      return {
        success: false,
        message: 'Failed to get waiting room queue'
      };
    }
  }
  
  /**
   * Check in a patient
   */
  async checkInPatient(appointmentId, checkedInBy, options = {}) {
    try {
      // Find or create waiting room entry
      let waitingRoomEntry = await WaitingRoomEntry.findOne({ appointmentId });
      
      if (!waitingRoomEntry) {
        // Get appointment data
        const appointment = await Appointment.findById(appointmentId);
        if (!appointment) {
          return {
            success: false,
            message: 'Appointment not found'
          };
        }
        
        // Create new waiting room entry
        waitingRoomEntry = new WaitingRoomEntry({
          appointmentId: appointmentId,
          doctorId: appointment.doctorId,
          patientName: appointment.patientName,
          date: appointment.date,
          scheduledTime: appointment.time,
          priority: options.priority || 'Normal'
        });
      }
      
      // Update status and check-in details
      waitingRoomEntry.status = 'Checked-in';
      waitingRoomEntry.checkedInAt = new Date();
      waitingRoomEntry.checkedInBy = checkedInBy;
      
      if (options.notes) {
        waitingRoomEntry.notes = options.notes;
      }
      
      if (options.priority) {
        waitingRoomEntry.priority = options.priority;
        waitingRoomEntry.priorityReason = options.priorityReason;
      }
      
      await waitingRoomEntry.save();
      
      // Update appointment status
      await Appointment.findByIdAndUpdate(appointmentId, {
        status: 'Checked-in'
      });
      
      // Log the event
      await this.logWaitingRoomEvent('PATIENT_CHECKED_IN', {
        appointmentId,
        patientName: waitingRoomEntry.patientName,
        doctorId: waitingRoomEntry.doctorId,
        checkedInBy,
        priority: waitingRoomEntry.priority
      });
      
      return {
        success: true,
        waitingRoomEntry,
        message: 'Patient checked in successfully'
      };
      
    } catch (error) {
      logger.error('Error checking in patient:', error);
      return {
        success: false,
        message: 'Failed to check in patient'
      };
    }
  }
  
  /**
   * Mark patient as no-show
   */
  async markNoShow(appointmentId, markedBy, reason) {
    try {
      const waitingRoomEntry = await WaitingRoomEntry.findOne({ appointmentId });
      
      if (!waitingRoomEntry) {
        return {
          success: false,
          message: 'Patient not found in waiting room'
        };
      }
      
      waitingRoomEntry.status = 'No-show';
      waitingRoomEntry.noShowReason = reason;
      waitingRoomEntry.markedNoShowBy = markedBy;
      
      await waitingRoomEntry.save();
      
      // Update appointment status
      await Appointment.findByIdAndUpdate(appointmentId, {
        status: 'No-show'
      });
      
      // Log the event
      await this.logWaitingRoomEvent('PATIENT_NO_SHOW', {
        appointmentId,
        patientName: waitingRoomEntry.patientName,
        doctorId: waitingRoomEntry.doctorId,
        reason,
        markedBy
      });
      
      return {
        success: true,
        waitingRoomEntry,
        message: 'Patient marked as no-show'
      };
      
    } catch (error) {
      logger.error('Error marking no-show:', error);
      return {
        success: false,
        message: 'Failed to mark patient as no-show'
      };
    }
  }
  
  /**
   * Start consultation
   */
  async startConsultation(appointmentId, startedBy) {
    try {
      const waitingRoomEntry = await WaitingRoomEntry.findOne({ appointmentId });
      
      if (!waitingRoomEntry) {
        return {
          success: false,
          message: 'Patient not found in waiting room'
        };
      }
      
      if (waitingRoomEntry.status !== 'Checked-in') {
        return {
          success: false,
          message: 'Patient must be checked in before starting consultation'
        };
      }
      
      waitingRoomEntry.status = 'In-progress';
      waitingRoomEntry.consultationStartedAt = new Date();
      waitingRoomEntry.consultationStartedBy = startedBy;
      
      await waitingRoomEntry.save();
      
      // Update appointment status
      await Appointment.findByIdAndUpdate(appointmentId, {
        status: 'In-progress'
      });
      
      // Log the event
      await this.logWaitingRoomEvent('CONSULTATION_STARTED', {
        appointmentId,
        patientName: waitingRoomEntry.patientName,
        doctorId: waitingRoomEntry.doctorId,
        startedBy
      });
      
      return {
        success: true,
        waitingRoomEntry,
        message: 'Consultation started'
      };
      
    } catch (error) {
      logger.error('Error starting consultation:', error);
      return {
        success: false,
        message: 'Failed to start consultation'
      };
    }
  }
  
  /**
   * Complete consultation
   */
  async completeConsultation(appointmentId, completedBy, options = {}) {
    try {
      const waitingRoomEntry = await WaitingRoomEntry.findOne({ appointmentId })
        .populate('appointmentId');
      
      if (!waitingRoomEntry) {
        return {
          success: false,
          message: 'Patient not found in waiting room'
        };
      }
      
      const completionTime = new Date();
      waitingRoomEntry.status = 'Completed';
      waitingRoomEntry.consultationCompletedAt = completionTime;
      waitingRoomEntry.consultationCompletedBy = completedBy;
      
      // Calculate actual consultation duration
      if (waitingRoomEntry.consultationStartedAt) {
        const duration = Math.floor(
          (completionTime - waitingRoomEntry.consultationStartedAt) / (1000 * 60)
        );
        waitingRoomEntry.actualConsultationDuration = duration;
      }
      
      // Override duration if provided
      if (options.actualDuration) {
        waitingRoomEntry.actualConsultationDuration = options.actualDuration;
      }
      
      // Add completion notes
      if (options.notes) {
        waitingRoomEntry.notes = waitingRoomEntry.notes 
          ? `${waitingRoomEntry.notes}\nCompletion: ${options.notes}`
          : `Completion: ${options.notes}`;
      }
      
      await waitingRoomEntry.save();
      
      // Update appointment status
      await Appointment.findByIdAndUpdate(appointmentId, {
        status: 'Completed'
      });
      
      // Log the event
      await this.logWaitingRoomEvent('CONSULTATION_COMPLETED', {
        appointmentId,
        patientName: waitingRoomEntry.patientName,
        doctorId: waitingRoomEntry.doctorId,
        completedBy,
        duration: waitingRoomEntry.actualConsultationDuration
      });
      
      return {
        success: true,
        waitingRoomEntry,
        appointment: waitingRoomEntry.appointmentId,
        message: 'Consultation completed successfully'
      };
      
    } catch (error) {
      logger.error('Error completing consultation:', error);
      return {
        success: false,
        message: 'Failed to complete consultation'
      };
    }
  }
  
  /**
   * Update patient priority
   */
  async updatePatientPriority(appointmentId, priority, updatedBy, reason) {
    try {
      const waitingRoomEntry = await WaitingRoomEntry.findOne({ appointmentId });
      
      if (!waitingRoomEntry) {
        return {
          success: false,
          message: 'Patient not found in waiting room'
        };
      }
      
      const oldPriority = waitingRoomEntry.priority;
      waitingRoomEntry.priority = priority;
      waitingRoomEntry.priorityReason = reason;
      
      await waitingRoomEntry.save();
      
      // Log priority change
      await this.logWaitingRoomEvent('PRIORITY_CHANGED', {
        appointmentId,
        patientName: waitingRoomEntry.patientName,
        doctorId: waitingRoomEntry.doctorId,
        oldPriority,
        newPriority: priority,
        reason,
        updatedBy
      });
      
      return {
        success: true,
        waitingRoomEntry,
        message: `Priority updated to ${priority}`
      };
      
    } catch (error) {
      logger.error('Error updating patient priority:', error);
      return {
        success: false,
        message: 'Failed to update patient priority'
      };
    }
  }
  
  /**
   * Send delay notifications to waiting patients
   */
  async sendDelayNotifications(doctorId, delayMinutes, reason) {
    try {
      // Get all waiting patients for this doctor
      const waitingPatients = await WaitingRoomEntry.find({
        doctorId: doctorId,
        status: { $in: ['Waiting', 'Checked-in'] },
        date: {
          $gte: new Date(new Date().setHours(0, 0, 0, 0)),
          $lte: new Date(new Date().setHours(23, 59, 59, 999))
        }
      }).populate('appointmentId');
      
      let notificationsSent = 0;
      const notifications = [];
      
      for (const entry of waitingPatients) {
        const appointment = entry.appointmentId;
        
        if (appointment.patientContact?.email || appointment.patientContact?.phone) {
          try {
            const notificationResult = await notificationService.sendDelayNotification({
              patientName: appointment.patientName,
              email: appointment.patientContact.email,
              phone: appointment.patientContact.phone,
              delayMinutes,
              reason,
              estimatedNewTime: this.calculateNewTime(appointment.time, delayMinutes)
            });
            
            if (notificationResult.success) {
              notificationsSent++;
              notifications.push({
                appointmentId: appointment._id,
                patientName: appointment.patientName,
                method: notificationResult.method,
                sent: true
              });
            }
          } catch (notifError) {
            logger.warn(`Failed to send notification to ${appointment.patientName}:`, notifError);
            notifications.push({
              appointmentId: appointment._id,
              patientName: appointment.patientName,
              sent: false,
              error: notifError.message
            });
          }
        }
      }
      
      // Log delay notification event
      await this.logWaitingRoomEvent('DELAY_NOTIFICATIONS_SENT', {
        doctorId,
        delayMinutes,
        reason,
        totalPatients: waitingPatients.length,
        notificationsSent
      });
      
      return {
        success: true,
        totalPatients: waitingPatients.length,
        notificationsSent,
        notifications,
        message: `Sent ${notificationsSent} delay notifications`
      };
      
    } catch (error) {
      logger.error('Error sending delay notifications:', error);
      return {
        success: false,
        message: 'Failed to send delay notifications'
      };
    }
  }
  
  /**
   * Get queue statistics
   */
  async getQueueStatistics(doctorId) {
    try {
      const today = new Date();
      const startOfDay = new Date(today.setHours(0, 0, 0, 0));
      const endOfDay = new Date(today.setHours(23, 59, 59, 999));
      
      const stats = await WaitingRoomEntry.aggregate([
        {
          $match: {
            doctorId: doctorId,
            date: { $gte: startOfDay, $lte: endOfDay }
          }
        },
        {
          $group: {
            _id: '$status',
            count: { $sum: 1 },
            avgWaitingTime: { $avg: '$totalWaitingTime' },
            avgConsultationDuration: { $avg: '$actualConsultationDuration' }
          }
        }
      ]);
      
      return {
        success: true,
        statistics: stats,
        summary: {
          totalPatients: stats.reduce((sum, stat) => sum + stat.count, 0),
          completed: stats.find(s => s._id === 'Completed')?.count || 0,
          inProgress: stats.find(s => s._id === 'In-progress')?.count || 0,
          waiting: stats.find(s => s._id === 'Waiting')?.count || 0,
          noShow: stats.find(s => s._id === 'No-show')?.count || 0
        }
      };
      
    } catch (error) {
      logger.error('Error getting queue statistics:', error);
      return {
        success: false,
        message: 'Failed to get queue statistics'
      };
    }
  }
  
  /**
   * Helper method to log waiting room events
   * @private
   */
  async logWaitingRoomEvent(eventType, data) {
    try {
      await rabbitmq.publishToExchange('logs', 'waiting_room.event', {
        type: eventType,
        timestamp: new Date(),
        data: data
      });
    } catch (error) {
      logger.warn('Failed to log waiting room event:', error);
    }
  }
  
  /**
   * Helper method to calculate new appointment time
   * @private
   */
  calculateNewTime(originalTime, delayMinutes) {
    const [hours, minutes] = originalTime.split(':').map(Number);
    const originalMinutes = hours * 60 + minutes;
    const newMinutes = originalMinutes + delayMinutes;
    
    const newHours = Math.floor(newMinutes / 60);
    const newMins = newMinutes % 60;
    
    return `${newHours.toString().padStart(2, '0')}:${newMins.toString().padStart(2, '0')}`;
  }
}

module.exports = new WaitingRoomService();