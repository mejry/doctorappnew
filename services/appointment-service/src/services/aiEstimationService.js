// appointment-service/src/services/aiEstimationService.js
const axios = require('axios');
const logger = require('../config/logger');
const config = require('../config/config');

/**
 * Service to communicate with Python AI estimation microservice
 */
class AIEstimationService {
  constructor() {
    this.aiServiceUrl = config.ai.serviceUrl || 'http://localhost:5001';
    this.timeout = config.ai.timeout || 5000;
  }
  
  /**
   * Calculate waiting time estimates for an entire queue
   * @param {Array} queue - Array of waiting room entries
   * @param {String} doctorId - Doctor ID
   * @returns {Array} Queue with AI estimates added
   */
  async calculateQueueEstimates(queue, doctorId) {
    try {
      // Prepare queue data for AI service
      const queueData = queue.map(entry => ({
        appointmentId: entry.appointmentId._id,
        patientName: entry.patientName,
        appointmentType: entry.appointmentId.type,
        scheduledTime: entry.scheduledTime,
        duration: entry.appointmentId.duration,
        status: entry.status,
        priority: entry.priority,
        checkedInAt: entry.checkedInAt,
        consultationStartedAt: entry.consultationStartedAt
      }));
      
      // Call Python AI service
      const response = await axios.post(`${this.aiServiceUrl}/calculate-queue-estimates`, {
        doctorId: doctorId,
        queue: queueData,
        timestamp: new Date().toISOString()
      }, {
        timeout: this.timeout,
        headers: {
          'Content-Type': 'application/json'
        }
      });
      
      if (response.data.success) {
        // Merge AI estimates back into queue entries
        const estimates = response.data.estimates;
        
        return queue.map((entry, index) => {
          const estimate = estimates[index];
          if (estimate) {
            entry.aiEstimate = {
              estimatedWaitingTime: estimate.estimatedWaitingTime,
              position: estimate.position,
              confidence: estimate.confidence,
              message: estimate.message,
              breakdown: estimate.breakdown,
              lastUpdated: new Date()
            };
          }
          return entry;
        });
      } else {
        logger.warn('AI service returned error:', response.data.message);
        return queue; // Return original queue without estimates
      }
      
    } catch (error) {
      logger.error('Error calling AI estimation service:', error.message);
      // Return queue without AI estimates if service is unavailable
      return queue;
    }
  }
  
  /**
   * Calculate waiting time for a specific patient
   * @param {String} appointmentId - Appointment ID
   * @param {String} doctorId - Doctor ID
   * @returns {Object} Waiting time estimation
   */
  async calculateWaitingTime(appointmentId, doctorId) {
    try {
      const response = await axios.post(`${this.aiServiceUrl}/calculate-waiting-time`, {
        appointmentId: appointmentId,
        doctorId: doctorId,
        timestamp: new Date().toISOString()
      }, {
        timeout: this.timeout,
        headers: {
          'Content-Type': 'application/json'
        }
      });
      
      return response.data;
      
    } catch (error) {
      logger.error('Error calculating waiting time:', error.message);
      return {
        success: false,
        message: 'AI estimation service unavailable',
        estimatedWaitingTime: null
      };
    }
  }
  
  /**
   * Update AI queue estimates for a doctor
   * @param {String} doctorId - Doctor ID
   */
  async updateQueueEstimates(doctorId) {
    try {
      await axios.post(`${this.aiServiceUrl}/update-queue`, {
        doctorId: doctorId,
        timestamp: new Date().toISOString()
      }, {
        timeout: this.timeout,
        headers: {
          'Content-Type': 'application/json'
        }
      });
      
      logger.debug(`Updated AI queue estimates for doctor ${doctorId}`);
      
    } catch (error) {
      logger.warn('Failed to update AI queue estimates:', error.message);
    }
  }
  
  /**
   * Train AI model with actual consultation data
   * @param {Object} trainingData - Training data
   */
  async trainModel(trainingData) {
    try {
      await axios.post(`${this.aiServiceUrl}/train`, trainingData, {
        timeout: this.timeout,
        headers: {
          'Content-Type': 'application/json'
        }
      });
      
      logger.debug('Sent training data to AI service');
      
    } catch (error) {
      logger.warn('Failed to send training data to AI service:', error.message);
    }
  }
  
  /**
   * Get AI insights for a doctor's queue
   * @param {String} doctorId - Doctor ID
   * @returns {Object} AI insights
   */
  async getAiInsights(doctorId) {
    try {
      const response = await axios.get(`${this.aiServiceUrl}/insights/${doctorId}`, {
        timeout: this.timeout
      });
      
      return response.data;
      
    } catch (error) {
      logger.warn('Failed to get AI insights:', error.message);
      return {
        success: false,
        message: 'AI insights unavailable'
      };
    }
  }
  
  /**
   * Check if AI service is available
   * @returns {Boolean} Service availability
   */
  async isAvailable() {
    try {
      const response = await axios.get(`${this.aiServiceUrl}/health`, {
        timeout: 2000
      });
      
      return response.status === 200;
      
    } catch (error) {
      return false;
    }
  }
}

module.exports = new AIEstimationService();