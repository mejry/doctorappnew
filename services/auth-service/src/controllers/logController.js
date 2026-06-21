// controllers/logController.js
const logService = require('../services/logService');

module.exports = {
  /**
   * Get logs with pagination and filtering
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
      
      const result = await logService.getLogs(
        filters,
        parseInt(page, 10),
        parseInt(limit, 10)
      );
      
      res.json(result);
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  },
  
  /**
   * Get logs for the current user
   * @param {Object} req - Express request
   * @param {Object} res - Express response
   */
  async getMyLogs(req, res) {
    try {
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
      
      const result = await logService.getUserLogs(
        req.user.id,
        filters,
        parseInt(page, 10),
        parseInt(limit, 10)
      );
      
      res.json(result);
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  },
  
  /**
   * Get logs for a specific user (admin only)
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
      
      const result = await logService.getUserLogs(
        userId,
        filters,
        parseInt(page, 10),
        parseInt(limit, 10)
      );
      
      res.json(result);
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  },
  
  /**
   * Get logs for a specific resource
   * @param {Object} req - Express request
   * @param {Object} res - Express response
   */
  async getResourceLogs(req, res) {
    try {
      const { resourceType, resourceId } = req.params;
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
      
      const result = await logService.getResourceLogs(
        resourceType,
        resourceId,
        filters,
        parseInt(page, 10),
        parseInt(limit, 10)
      );
      
      res.json(result);
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  },
  
  /**
   * Get all log categories for filtering
   * @param {Object} req - Express request
   * @param {Object} res - Express response
   */
  async getLogCategories(req, res) {
    try {
      const categories = await logService.getLogCategories();
      res.json(categories);
    } catch (err) {
      res.status(500).json({ error: err.message });
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
      
      const csv = await logService.exportLogs(filters);
      
      // Set headers for file download
      res.setHeader('Content-Type', 'text/csv');
      res.setHeader('Content-Disposition', 'attachment; filename=logs.csv');
      
      res.send(csv);
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  }
};