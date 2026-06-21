// auth-service/src/services/adminLogService.js
// Import a simple console logger until your actual logger is properly set up
const logger = {
    info: (message, ...args) => console.log(`[INFO] ${message}`, ...args),
    warn: (message, ...args) => console.log(`[WARN] ${message}`, ...args),
    error: (message, ...args) => console.error(`[ERROR] ${message}`, ...args),
    debug: (message, ...args) => console.log(`[DEBUG] ${message}`, ...args)
  };
  
  const LogEntry = require('../models/LogEntry');
  
  /**
   * Service for admin access to system logs
   */
  class AdminLogService {
    /**
     * Get logs with filtering and pagination
     * @param {Object} filters - Filters for logs
     * @param {Number} page - Page number (1-based)
     * @param {Number} limit - Items per page
     * @returns {Object} - Logs with pagination data
     */
    async getLogs(filters = {}, page = 1, limit = 50) {
      try {
        // Build MongoDB query from filters
        const query = this._buildQuery(filters);
        
        // Calculate pagination
        const skip = (page - 1) * limit;
        
        // Get total count for pagination
        const total = await LogEntry.countDocuments(query);
        
        // Get logs with pagination and sorting
        const logs = await LogEntry.find(query)
          .populate('userId', 'email firstname lastname role')
          .sort({ timestamp: -1 }) // Newest first
          .skip(skip)
          .limit(limit);
        
        // Calculate pagination info
        const totalPages = Math.ceil(total / limit);
        
        return {
          success: true,
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
      } catch (error) {
        logger.error('Error fetching logs:', error);
        return {
          success: false,
          message: error.message
        };
      }
    }
    
    /**
     * Get logs for a specific user
     * @param {String} userId - User ID
     * @param {Object} filters - Additional filters
     * @param {Number} page - Page number
     * @param {Number} limit - Items per page
     * @returns {Object} - Logs with pagination data
     */
    async getUserLogs(userId, filters = {}, page = 1, limit = 20) {
      // Add userId to filters
      const userFilters = { ...filters, userId };
      return this.getLogs(userFilters, page, limit);
    }
    
    /**
     * Get logs for a specific appointment
     * @param {String} appointmentId - Appointment ID
     * @param {Object} filters - Additional filters
     * @param {Number} page - Page number
     * @param {Number} limit - Items per page
     * @returns {Object} - Logs with pagination data
     */
    async getAppointmentLogs(appointmentId, filters = {}, page = 1, limit = 20) {
      // Add resourceId to filters and ensure resourceType is appointment
      const appointmentFilters = {
        ...filters,
        resourceId: appointmentId,
        resourceType: 'appointment'
      };
      return this.getLogs(appointmentFilters, page, limit);
    }
    
    /**
     * Get statistics about logs
     * @param {Object} filters - Filters for logs
     * @returns {Object} - Log statistics
     */
    async getLogStats(filters = {}) {
      try {
        // Build MongoDB query from filters
        const query = this._buildQuery(filters);
        
        // Get total count
        const total = await LogEntry.countDocuments(query);
        
        // Get action counts
        const actionCounts = await LogEntry.aggregate([
          { $match: query },
          { $group: { _id: '$action', count: { $sum: 1 } } },
          { $sort: { count: -1 } }
        ]);
        
        // Get resource type counts
        const resourceTypeCounts = await LogEntry.aggregate([
          { $match: query },
          { $group: { _id: '$resourceType', count: { $sum: 1 } } },
          { $sort: { count: -1 } }
        ]);
        
        // Get event type counts
        const eventTypeCounts = await LogEntry.aggregate([
          { $match: query },
          { $group: { _id: '$eventType', count: { $sum: 1 } } },
          { $sort: { count: -1 } }
        ]);
        
        // Get user counts (top 10)
        const userCounts = await LogEntry.aggregate([
          { $match: query },
          { $group: { _id: '$userId', count: { $sum: 1 } } },
          { $sort: { count: -1 } },
          { $limit: 10 }
        ]);
        
        // Get logs per day (last 30 days)
        const thirtyDaysAgo = new Date();
        thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
        
        const logsPerDay = await LogEntry.aggregate([
          { 
            $match: { 
              ...query, 
              timestamp: { $gte: thirtyDaysAgo } 
            } 
          },
          {
            $group: {
              _id: {
                year: { $year: '$timestamp' },
                month: { $month: '$timestamp' },
                day: { $dayOfMonth: '$timestamp' }
              },
              count: { $sum: 1 }
            }
          },
          { $sort: { '_id.year': 1, '_id.month': 1, '_id.day': 1 } }
        ]);
        
        // Format logs per day for easier consumption
        const formattedLogsPerDay = logsPerDay.map(item => ({
          date: new Date(item._id.year, item._id.month - 1, item._id.day).toISOString().split('T')[0],
          count: item.count
        }));
        
        return {
          success: true,
          stats: {
            total,
            actions: actionCounts.map(item => ({ action: item._id, count: item.count })),
            resourceTypes: resourceTypeCounts.map(item => ({ resourceType: item._id, count: item.count })),
            eventTypes: eventTypeCounts.map(item => ({ eventType: item._id, count: item.count })),
            topUsers: userCounts.map(item => ({ userId: item._id, count: item.count })),
            logsPerDay: formattedLogsPerDay
          }
        };
      } catch (error) {
        logger.error('Error fetching log stats:', error);
        return {
          success: false,
          message: error.message
        };
      }
    }
    
    /**
     * Get all event types, actions, and resource types for filtering UI
     * @returns {Object} - Filter options
     */
    async getLogFilterOptions() {
      try {
        // Get distinct values from the log collection
        const [eventTypes, actions, resourceTypes] = await Promise.all([
          LogEntry.distinct('eventType'),
          LogEntry.distinct('action'),
          LogEntry.distinct('resourceType')
        ]);
        
        return {
          success: true,
          filterOptions: {
            eventTypes: eventTypes.sort(),
            actions: actions.sort(),
            resourceTypes: resourceTypes.sort()
          }
        };
      } catch (error) {
        logger.error('Error fetching log filter options:', error);
        return {
          success: false,
          message: error.message
        };
      }
    }
    
    /**
     * Export logs to CSV format
     * @param {Object} filters - Filters for logs
     * @returns {String} - CSV string
     */
    async exportLogs(filters = {}) {
      try {
        // Build MongoDB query from filters
        const query = this._buildQuery(filters);
        
        // Get all matching logs (no pagination)
        const logs = await LogEntry.find(query)
          .populate('userId', 'email')
          .sort({ timestamp: -1 });
        
        // Convert to CSV
        const headers = [
          'Timestamp',
          'Event Type',
          'Action',
          'Resource Type',
          'Resource ID',
          'User',
          'Message',
          'IP Address'
        ].join(',');
        
        const rows = logs.map(log => {
          const timestamp = log.timestamp.toISOString();
          const eventType = log.eventType || '';
          const action = log.action || '';
          const resourceType = log.resourceType || '';
          const resourceId = log.resourceId || '';
          const user = log.userId ? (log.userId.email || log.userId) : 'System';
          const message = log.message || '';
          const ip = log.ipAddress || '';
          
          // Escape fields for CSV format
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
            resourceId,
            escapeCsv(user),
            escapeCsv(message),
            escapeCsv(ip)
          ].join(',');
        }).join('\n');
        
        return headers + '\n' + rows;
      } catch (error) {
        logger.error('Error exporting logs:', error);
        throw error;
      }
    }
    
    /**
     * Build MongoDB query from filter parameters
     * @param {Object} filters - Filter parameters
     * @returns {Object} - MongoDB query
     * @private
     */
    _buildQuery(filters) {
      const query = {};
      
      // Date range filters
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
      
      // User ID filter
      if (filters.userId) {
        query.userId = filters.userId;
      }
      
      // Event type filter
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
      
      // IP address filter
      if (filters.ipAddress) {
        query.ipAddress = filters.ipAddress;
      }
      
      // Text search (message content)
      if (filters.searchText) {
        query.$text = { $search: filters.searchText };
      }
      
      return query;
    }
  }
  
  // Export a singleton instance
  module.exports = new AdminLogService();