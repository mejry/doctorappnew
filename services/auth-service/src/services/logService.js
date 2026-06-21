// services/logService.js
const LogEntry = require('../models/LogEntry');

module.exports = {
  /**
   * Get logs with filtering options
   * @param {Object} filters - Filters for logs
   * @param {Number} page - Page number for pagination
   * @param {Number} limit - Items per page
   * @returns {Object} Logs with pagination info
   */
  async getLogs(filters = {}, page = 1, limit = 50) {
    // Build query based on filters
    const query = {};
    
    // Date range
    if (filters.startDate && filters.endDate) {
      query.timestamp = {
        $gte: new Date(filters.startDate),
        $lte: new Date(filters.endDate)
      };
    } else if (filters.startDate) {
      query.timestamp = { $gte: new Date(filters.startDate) };
    } else if (filters.endDate) {
      query.timestamp = { $lte: new Date(filters.endDate) };
    }
    
    // User ID
    if (filters.userId) {
      query.userId = filters.userId;
    }
    
    // Target ID (for user management logs)
    if (filters.targetId) {
      query.targetId = filters.targetId;
    }
    
    // Event type (or multiple event types)
    if (filters.eventType) {
      if (Array.isArray(filters.eventType)) {
        query.eventType = { $in: filters.eventType };
      } else {
        query.eventType = filters.eventType;
      }
    }
    
    // Action filter
    if (filters.action) {
      if (Array.isArray(filters.action)) {
        query.action = { $in: filters.action };
      } else {
        query.action = filters.action;
      }
    }
    
    // Resource type filter
    if (filters.resourceType) {
      query.resourceType = filters.resourceType;
    }
    
    // Resource ID filter
    if (filters.resourceId) {
      query.resourceId = filters.resourceId;
    }
    
    // IP address
    if (filters.ipAddress) {
      query.ipAddress = filters.ipAddress;
    }

    // Calculate pagination
    const skip = (page - 1) * limit;
    
    // Get total count for pagination
    const total = await LogEntry.countDocuments(query);
    
    // Get logs with pagination
    const logs = await LogEntry.find(query)
      .populate('userId', 'email firstname lastname')
      .populate('targetId', 'email firstname lastname')
      .sort('-timestamp')
      .skip(skip)
      .limit(limit);
      
    // Calculate pagination info
    const totalPages = Math.ceil(total / limit);
    
    return {
      logs,
      pagination: {
        total,
        page,
        limit,
        totalPages,
        hasNext: page < totalPages,
        hasPrev: page > 1
      }
    };
  },
  
  /**
   * Get logs for a specific user
   * @param {String} userId - User ID
   * @param {Object} filters - Additional filters
   * @param {Number} page - Page number
   * @param {Number} limit - Items per page
   * @returns {Object} User logs with pagination
   */
  async getUserLogs(userId, filters = {}, page = 1, limit = 20) {
    return this.getLogs(
      { ...filters, userId },
      page,
      limit
    );
  },
  
  /**
   * Get logs for a specific resource
   * @param {String} resourceType - Resource type
   * @param {String} resourceId - Resource ID
   * @param {Object} filters - Additional filters
   * @param {Number} page - Page number
   * @param {Number} limit - Items per page
   * @returns {Object} Resource logs with pagination
   */
  async getResourceLogs(resourceType, resourceId, filters = {}, page = 1, limit = 20) {
    return this.getLogs(
      { ...filters, resourceType, resourceId },
      page,
      limit
    );
  },
  
  /**
   * Get all event types for filtering
   * @returns {Object} Object with event types, actions, and resource types
   */
  async getLogCategories() {
    // Get distinct values from the log collection
    const eventTypes = await LogEntry.distinct('eventType');
    const actions = await LogEntry.distinct('action');
    const resourceTypes = await LogEntry.distinct('resourceType');
    
    return {
      eventTypes: eventTypes.sort(),
      actions: actions.sort(),
      resourceTypes: resourceTypes.sort()
    };
  },
  
  /**
   * Export logs to CSV format
   * @param {Object} filters - Filters for logs
   * @returns {String} CSV string
   */
  async exportLogs(filters = {}) {
    // Build query based on filters (same as getLogs)
    const query = {};
    
    if (filters.startDate && filters.endDate) {
      query.timestamp = {
        $gte: new Date(filters.startDate),
        $lte: new Date(filters.endDate)
      };
    }
    
    if (filters.userId) query.userId = filters.userId;
    if (filters.eventType) {
      if (Array.isArray(filters.eventType)) {
        query.eventType = { $in: filters.eventType };
      } else {
        query.eventType = filters.eventType;
      }
    }
    
    if (filters.action) query.action = filters.action;
    if (filters.resourceType) query.resourceType = filters.resourceType;
    if (filters.resourceId) query.resourceId = filters.resourceId;
    
    // Get all matching logs (no pagination)
    const logs = await LogEntry.find(query)
      .populate('userId', 'email')
      .populate('targetId', 'email')
      .sort('-timestamp');
      
    // Convert to CSV
    const headers = 'Timestamp,Event Type,Action,Resource Type,User,Target,Message,IP Address\n';
    
    const rows = logs.map(log => {
      const timestamp = log.timestamp.toISOString();
      const eventType = log.eventType || '';
      const action = log.action || '';
      const resourceType = log.resourceType || '';
      const user = log.userId ? log.userId.email : 'System';
      const target = log.targetId ? log.targetId.email : '';
      const message = log.message || '';
      const ip = log.ipAddress || '';
      
      // Escape CSV fields properly
      const escapeCsv = (field) => {
        if (typeof field !== 'string') return field;
        if (field.includes(',') || field.includes('"') || field.includes('\n')) {
          return `"${field.replace(/"/g, '""')}"`;
        }
        return field;
      };
      
      return [
        timestamp,
        escapeCsv(eventType),
        escapeCsv(action),
        escapeCsv(resourceType),
        escapeCsv(user),
        escapeCsv(target),
        escapeCsv(message),
        escapeCsv(ip)
      ].join(',');
    }).join('\n');
    
    return headers + rows;
  }
};