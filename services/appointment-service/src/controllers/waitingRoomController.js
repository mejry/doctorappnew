// appointment-service/src/controllers/waitingRoomController.js
const waitingRoomService = require('../services/waitingRoomService');
const aiEstimationService = require('../services/aiEstimationService');
const logger = require('../config/logger');

class WaitingRoomController {
  
  /**
   * Get today's waiting room queue for a doctor
   * DA-60000: Display list of patients with appointments today, sorted by time
   */
  async getTodaysQueue(req, res) {
    try {
      const { doctorId } = req.params;
      const { includeAiEstimates = 'true' } = req.query;
      
      logger.info(`Getting today's queue for doctor ${doctorId}`);
      
      const result = await waitingRoomService.getTodaysQueue(doctorId);
      
      if (!result.success) {
        return res.status(400).json(result);
      }
      
      // Add AI-powered waiting time estimates if requested
      if (includeAiEstimates === 'true') {
        try {
          const queueWithEstimates = await aiEstimationService.calculateQueueEstimates(
            result.queue,
            doctorId
          );
          result.queue = queueWithEstimates;
        } catch (aiError) {
          logger.warn('Failed to get AI estimates:', aiError);
          // Continue without AI estimates
        }
      }
      
      res.json(result);
      
    } catch (error) {
      logger.error('Error getting today\'s queue:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }
  
  /**
   * Check in a patient
   * DA-60001: Allow reception staff to mark patient as "Checked-In"
   */
  async checkInPatient(req, res) {
    try {
      const { appointmentId } = req.params;
      const { notes, priority, priorityReason } = req.body;
      const checkedInBy = req.user?.id;
      
      logger.info(`Checking in patient for appointment ${appointmentId}`);
      
      const result = await waitingRoomService.checkInPatient(
        appointmentId, 
        checkedInBy, 
        { notes, priority, priorityReason }
      );
      
      if (!result.success) {
        return res.status(400).json(result);
      }
      
      // Trigger AI recalculation for the affected doctor's queue
      try {
        await aiEstimationService.updateQueueEstimates(result.waitingRoomEntry.doctorId);
      } catch (aiError) {
        logger.warn('Failed to update AI estimates after check-in:', aiError);
      }
      
      res.json(result);
      
    } catch (error) {
      logger.error('Error checking in patient:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }
  
  /**
   * Mark patient as no-show
   * DA-60002: Allow marking patient as "No-Show"
   */
  async markNoShow(req, res) {
    try {
      const { appointmentId } = req.params;
      const { reason } = req.body;
      const markedBy = req.user?.id;
      
      logger.info(`Marking appointment ${appointmentId} as no-show`);
      
      const result = await waitingRoomService.markNoShow(
        appointmentId, 
        markedBy, 
        reason
      );
      
      if (!result.success) {
        return res.status(400).json(result);
      }
      
      // Update AI estimates after no-show
      try {
        await aiEstimationService.updateQueueEstimates(result.waitingRoomEntry.doctorId);
      } catch (aiError) {
        logger.warn('Failed to update AI estimates after no-show:', aiError);
      }
      
      res.json(result);
      
    } catch (error) {
      logger.error('Error marking no-show:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }
  
  /**
   * Start consultation
   */
  async startConsultation(req, res) {
    try {
      const { appointmentId } = req.params;
      const startedBy = req.user?.id;
      
      logger.info(`Starting consultation for appointment ${appointmentId}`);
      
      const result = await waitingRoomService.startConsultation(
        appointmentId, 
        startedBy
      );
      
      if (!result.success) {
        return res.status(400).json(result);
      }
      
      // Update AI estimates when consultation starts
      try {
        await aiEstimationService.updateQueueEstimates(result.waitingRoomEntry.doctorId);
      } catch (aiError) {
        logger.warn('Failed to update AI estimates after consultation start:', aiError);
      }
      
      res.json(result);
      
    } catch (error) {
      logger.error('Error starting consultation:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }
  
  /**
   * Complete consultation
   * DA-60003: Allow doctor to mark consultation as "Completed"
   */
  async completeConsultation(req, res) {
    try {
      const { appointmentId } = req.params;
      const { notes, actualDuration } = req.body;
      const completedBy = req.user?.id;
      
      logger.info(`Completing consultation for appointment ${appointmentId}`);
      
      const result = await waitingRoomService.completeConsultation(
        appointmentId, 
        completedBy,
        { notes, actualDuration }
      );
      
      if (!result.success) {
        return res.status(400).json(result);
      }
      
      // Update AI model with actual consultation data for learning
      if (actualDuration) {
        try {
          await aiEstimationService.trainModel({
            doctorId: result.waitingRoomEntry.doctorId,
            appointmentType: result.appointment.type,
            scheduledDuration: result.appointment.duration,
            actualDuration: actualDuration,
            timeOfDay: new Date().getHours(),
            dayOfWeek: new Date().getDay()
          });
        } catch (aiError) {
          logger.warn('Failed to update AI model:', aiError);
        }
      }
      
      // Update queue estimates
      try {
        await aiEstimationService.updateQueueEstimates(result.waitingRoomEntry.doctorId);
      } catch (aiError) {
        logger.warn('Failed to update AI estimates after completion:', aiError);
      }
      
      res.json(result);
      
    } catch (error) {
      logger.error('Error completing consultation:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }
  
  /**
   * Update patient priority
   * DA-60005: Allow prioritizing patients in emergencies
   */
  async updatePatientPriority(req, res) {
    try {
      const { appointmentId } = req.params;
      const { priority, reason } = req.body;
      const updatedBy = req.user?.id;
      
      logger.info(`Updating priority for appointment ${appointmentId} to ${priority}`);
      
      const result = await waitingRoomService.updatePatientPriority(
        appointmentId,
        priority,
        updatedBy,
        reason
      );
      
      if (!result.success) {
        return res.status(400).json(result);
      }
      
      // Update AI estimates after priority change
      try {
        await aiEstimationService.updateQueueEstimates(result.waitingRoomEntry.doctorId);
      } catch (aiError) {
        logger.warn('Failed to update AI estimates after priority change:', aiError);
      }
      
      res.json(result);
      
    } catch (error) {
      logger.error('Error updating patient priority:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }
  
  /**
   * Get waiting time estimate for specific patient
   * DA-60006: Display expected waiting time for each patient
   */
  async getWaitingTimeEstimate(req, res) {
    try {
      const { appointmentId } = req.params;
      const { doctorId } = req.query;
      
      logger.info(`Getting waiting time estimate for appointment ${appointmentId}`);
      
      const estimation = await aiEstimationService.calculateWaitingTime(
        appointmentId, 
        doctorId
      );
      
      res.json(estimation);
      
    } catch (error) {
      logger.error('Error getting waiting time estimate:', error);
      res.status(500).json({
        success: false,
        message: 'Unable to calculate waiting time'
      });
    }
  }
  
  /**
   * Send delay notifications
   * DA-60004: Notify patients if appointment is delayed
   */
  async sendDelayNotifications(req, res) {
    try {
      const { doctorId } = req.params;
      const { delayMinutes, reason } = req.body;
      
      logger.info(`Sending delay notifications for doctor ${doctorId}, delay: ${delayMinutes}min`);
      
      const result = await waitingRoomService.sendDelayNotifications(
        doctorId,
        delayMinutes,
        reason
      );
      
      res.json(result);
      
    } catch (error) {
      logger.error('Error sending delay notifications:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to send delay notifications'
      });
    }
  }
  
  /**
   * Get queue statistics with AI insights
   */
  async getQueueStatistics(req, res) {
    try {
      const { doctorId } = req.params;
      
      logger.info(`Getting queue statistics for doctor ${doctorId}`);
      
      const [queueStats, aiInsights] = await Promise.all([
        waitingRoomService.getQueueStatistics(doctorId),
        aiEstimationService.getAiInsights(doctorId)
      ]);
      
      res.json({
        success: true,
        statistics: queueStats,
        aiInsights: aiInsights
      });
      
    } catch (error) {
      logger.error('Error getting queue statistics:', error);
      res.status(500).json({
        success: false,
        message: 'Unable to get queue statistics'
      });
    }
  }
}

module.exports = new WaitingRoomController();