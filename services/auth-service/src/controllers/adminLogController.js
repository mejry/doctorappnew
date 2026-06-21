// auth-service/src/controllers/adminLogController.js
// Import a simple console logger until your actual logger is properly set up
const logger = {
    info: (message, ...args) => console.log(`[INFO] ${message}`, ...args),
    warn: (message, ...args) => console.log(`[WARN] ${message}`, ...args),
    error: (message, ...args) => console.error(`[ERROR] ${message}`, ...args),
    debug: (message, ...args) => console.log(`[DEBUG] ${message}`, ...args)
  };
  
  const adminLogService = require('../services/adminLogService');
  
  /**
   * Controller for admin log management
   */
  module.exports = {
    /**
     * Get logs with filtering and pagination
     * @param {Object} req - Express request
     * @param {Object} res - Express response
     */
    async getLogs(req, res) {
      try {
        const { 
          startDate, 
          endDate, 
          userId, 
          eventType,
          action,
          resourceType,
          resourceId,
          searchText,
          page = 1, 
          limit = 50 
        } = req.query;
        
        // Build filters object
        const filters = {};
        
        if (startDate) filters.startDate = startDate;
        if (endDate) filters.endDate = endDate;
        if (userId) filters.userId = userId;
        if (eventType) filters.eventType = eventType;
        if (action) filters.action = action;
        if (resourceType) filters.resourceType = resourceType;
        if (resourceId) filters.resourceId = resourceId;
        if (searchText) filters.searchText = searchText;
        
        const result = await adminLogService.getLogs(
          filters,
          parseInt(page, 10),
          parseInt(limit, 10)
        );
        
        res.json(result);
      } catch (err) {
        logger.error('Error in getLogs controller:', err);
        res.status(500).json({ success: false, message: err.message });
      }
    },
    
    /**
     * Get logs for a specific user
     * @param {Object} req - Express request
     * @param {Object} res - Express response
     */
    async getUserLogs(req, res) {
      try {
        const { userId } = req.params;
        const { 
          startDate, 
          endDate, 
          eventType,
          action,
          resourceType, 
          page = 1, 
          limit = 20 
        } = req.query;
        
        // Build filters object
        const filters = {};
        
        if (startDate) filters.startDate = startDate;
        if (endDate) filters.endDate = endDate;
        if (eventType) filters.eventType = eventType;
        if (action) filters.action = action;
        if (resourceType) filters.resourceType = resourceType;
        
        const result = await adminLogService.getUserLogs(
          userId,
          filters,
          parseInt(page, 10),
          parseInt(limit, 10)
        );
        
        res.json(result);
      } catch (err) {
        logger.error('Error in getUserLogs controller:', err);
        res.status(500).json({ success: false, message: err.message });
      }
    },
    
    /**
     * Get logs for a specific appointment
     * @param {Object} req - Express request
     * @param {Object} res - Express response
     */
    async getAppointmentLogs(req, res) {
      try {
        const { appointmentId } = req.params;
        const { 
          startDate, 
          endDate, 
          userId,
          action, 
          page = 1, 
          limit = 20 
        } = req.query;
        
        // Build filters object
        const filters = {};
        
        if (startDate) filters.startDate = startDate;
        if (endDate) filters.endDate = endDate;
        if (userId) filters.userId = userId;
        if (action) filters.action = action;
        
        const result = await adminLogService.getAppointmentLogs(
          appointmentId,
          filters,
          parseInt(page, 10),
          parseInt(limit, 10)
        );
        
        res.json(result);
      } catch (err) {
        logger.error('Error in getAppointmentLogs controller:', err);
        res.status(500).json({ success: false, message: err.message });
      }
    },
    
    /**
     * Get log statistics
     * @param {Object} req - Express request
     * @param {Object} res - Express response
     */
    async getLogStats(req, res) {
      try {
        const { 
          startDate, 
          endDate, 
          resourceType
        } = req.query;
        
        // Build filters object
        const filters = {};
        
        if (startDate) filters.startDate = startDate;
        if (endDate) filters.endDate = endDate;
        if (resourceType) filters.resourceType = resourceType;
        
        const result = await adminLogService.getLogStats(filters);
        
        res.json(result);
      } catch (err) {
        logger.error('Error in getLogStats controller:', err);
        res.status(500).json({ success: false, message: err.message });
      }
    },
    
    /**
     * Get filter options for logs UI
     * @param {Object} req - Express request
     * @param {Object} res - Express response
     */
    async getLogFilterOptions(req, res) {
      try {
        const result = await adminLogService.getLogFilterOptions();
        res.json(result);
      } catch (err) {
        logger.error('Error in getLogFilterOptions controller:', err);
        res.status(500).json({ success: false, message: err.message });
      }
    },
    
    /**
     * Export logs to CSV
     * @param {Object} req - Express request
     * @param {Object} res - Express response
     */
    async exportLogs(req, res) {
      try {
        const { 
          startDate, 
          endDate, 
          userId, 
          eventType,
          action,
          resourceType,
          resourceId
        } = req.query;
        
        // Build filters object
        const filters = {};
        
        if (startDate) filters.startDate = startDate;
        if (endDate) filters.endDate = endDate;
        if (userId) filters.userId = userId;
        if (eventType) filters.eventType = eventType;
        if (action) filters.action = action;
        if (resourceType) filters.resourceType = resourceType;
        if (resourceId) filters.resourceId = resourceId;
        
        const csv = await adminLogService.exportLogs(filters);
        
        // Set headers for file download
        res.setHeader('Content-Type', 'text/csv');
        res.setHeader('Content-Disposition', 'attachment; filename=logs.csv');
        
        res.send(csv);
      } catch (err) {
        logger.error('Error in exportLogs controller:', err);
        res.status(500).json({ success: false, message: err.message });
      }
    }
  };