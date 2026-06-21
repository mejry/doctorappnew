// appointment-service/src/controllers/appointmentController.js
const appointmentService = require('../services/appointmentService');
const logger = require('../config/logger');

/**
 * Create a new appointment
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
async function createAppointment(req, res) {
  try {
    // Log who is creating the appointment
    logger.debug(`Creating appointment by user ${req.user?.id || 'unknown'} with role ${req.user?.role || 'unknown'}`);
    
    // Make sure to include the user ID in the appointment data
    if (req.user) {
      req.body.createdBy = req.user.id;
    }
    
    const result = await appointmentService.createAppointment(req.body);
    
    if (!result.success) {
      return res.status(400).json(result);
    }
    
    res.status(201).json(result);
  } catch (error) {
    logger.error('Error in createAppointment controller:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
}

/**
 * Update an existing appointment
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
async function updateAppointment(req, res) {
  try {
    // Log who is updating the appointment
    logger.debug(`Updating appointment ${req.params.id} by user ${req.user?.id || 'unknown'} with role ${req.user?.role || 'unknown'}`);
    
    // Make sure to include the user ID in the update data
    if (req.user) {
      req.body.updatedBy = req.user.id;
    }
    
    const { id } = req.params;
    const result = await appointmentService.updateAppointment(id, req.body);
    
    if (!result.success) {
      return res.status(400).json(result);
    }
    
    res.status(200).json(result);
  } catch (error) {
    logger.error('Error in updateAppointment controller:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
}

/**
 * Get all appointments with filtering
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
async function getAppointments(req, res) {
  try {
    // Log who is fetching appointments
    logger.debug(`Fetching appointments by user ${req.user?.id || 'unknown'} with role ${req.user?.role || 'unknown'}`);
    
    // Extract filter parameters from query
    const filters = {
      doctorId: req.query.doctorId,
      patientName: req.query.patientName,
      date: req.query.date,
      startDate: req.query.startDate,
      endDate: req.query.endDate,
      status: req.query.status,
      type: req.query.type,
      limit: req.query.limit,
      skip: req.query.skip
    };
    
    // Handle sort parameter
    if (req.query.sort) {
      const [field, order] = req.query.sort.split(':');
      filters.sort = { [field]: order === 'desc' ? -1 : 1 };
    }
    
    const result = await appointmentService.getAppointments(filters);
    res.status(200).json(result);
  } catch (error) {
    logger.error('Error in getAppointments controller:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
}

/**
 * Get appointment by ID
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
async function getAppointmentById(req, res) {
  try {
    // Log who is fetching the appointment
    logger.debug(`Fetching appointment ${req.params.id} by user ${req.user?.id || 'unknown'} with role ${req.user?.role || 'unknown'}`);
    
    const { id } = req.params;
    const result = await appointmentService.getAppointmentById(id);
    
    if (!result.success) {
      return res.status(404).json(result);
    }
    
    res.status(200).json(result);
  } catch (error) {
    logger.error('Error in getAppointmentById controller:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
}

/**
 * Cancel an appointment
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
async function cancelAppointment(req, res) {
  try {
    // Log who is cancelling the appointment
    logger.debug(`Cancelling appointment ${req.params.id} by user ${req.user?.id || 'unknown'} with role ${req.user?.role || 'unknown'}`);
    
    const { id } = req.params;
    const { cancellationReason } = req.body;
    
    if (!cancellationReason) {
      return res.status(400).json({
        success: false,
        message: 'Cancellation reason is required'
      });
    }
    
    // Make sure to include the user ID in the update data
    if (req.user) {
      req.body.updatedBy = req.user.id;
    }
    
    const result = await appointmentService.updateAppointment(id, {
      status: 'Cancelled',
      cancellationReason,
      updatedBy: req.user?.id
    });
    
    if (!result.success) {
      return res.status(400).json(result);
    }
    
    res.status(200).json(result);
  } catch (error) {
    logger.error('Error in cancelAppointment controller:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
}

/**
 * Get appointments for specific view (daily, weekly, monthly)
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
async function getAppointmentsByView(req, res) {
  try {
    // Log who is fetching appointments
    logger.debug(`Fetching appointments by view ${req.params.view} by user ${req.user?.id || 'unknown'} with role ${req.user?.role || 'unknown'}`);
    
    const { view } = req.params;
    const { date, doctorId } = req.query;
    
    // Calculate date range based on view
    let startDate, endDate;
    const baseDate = date ? new Date(date) : new Date();
    
    switch (view) {
      case 'daily':
        startDate = new Date(baseDate);
        startDate.setHours(0, 0, 0, 0);
        
        endDate = new Date(baseDate);
        endDate.setHours(23, 59, 59, 999);
        break;
        
      case 'weekly':
        // Get first day of week (Sunday)
        const day = baseDate.getDay();
        startDate = new Date(baseDate);
        startDate.setDate(baseDate.getDate() - day);
        startDate.setHours(0, 0, 0, 0);
        
        endDate = new Date(startDate);
        endDate.setDate(startDate.getDate() + 6);
        endDate.setHours(23, 59, 59, 999);
        break;
        
      case 'monthly':
        startDate = new Date(baseDate.getFullYear(), baseDate.getMonth(), 1);
        startDate.setHours(0, 0, 0, 0);
        
        endDate = new Date(baseDate.getFullYear(), baseDate.getMonth() + 1, 0);
        endDate.setHours(23, 59, 59, 999);
        break;
        
      default:
        return res.status(400).json({
          success: false,
          message: 'Invalid view parameter. Use daily, weekly, or monthly.'
        });
    }
    
    // Get appointments for the date range
    const filters = {
      startDate: startDate.toISOString(),
      endDate: endDate.toISOString(),
      doctorId,
      sort: { date: 1, time: 1 }
    };
    
    const result = await appointmentService.getAppointments(filters);
    
    // Add period information to response
    res.status(200).json({
      ...result,
      view,
      period: {
        start: startDate,
        end: endDate
      }
    });
  } catch (error) {
    logger.error(`Error in getAppointmentsByView (${req.params.view}) controller:`, error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
}

/**
 * Get today's appointments (for waiting room)
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
async function getTodayAppointments(req, res) {
  try {
    // Log who is fetching today's appointments
    logger.debug(`Fetching today's appointments by user ${req.user?.id || 'unknown'} with role ${req.user?.role || 'unknown'}`);
    
    const { doctorId } = req.query;
    const result = await appointmentService.getTodayAppointments(doctorId);
    
    res.status(200).json(result);
  } catch (error) {
    logger.error('Error in getTodayAppointments controller:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
}

/**
 * Send appointment reminders for tomorrow
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
async function sendAppointmentReminders(req, res) {
  try {
    // Log who is sending reminders
    logger.debug(`Sending appointment reminders triggered by user ${req.user?.id || 'unknown'} with role ${req.user?.role || 'unknown'}`);
    
    const result = await appointmentService.scheduleReminders();
    res.status(200).json(result);
  } catch (error) {
    logger.error('Error in sendAppointmentReminders controller:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
}
/**
 * Get monthly appointment count for a doctor
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
async function getMonthlyAppointmentCount(req, res) {
  try {
    const { doctorId, year, month } = req.params;
    
    // Log who is requesting the count
    logger.debug(`Getting monthly appointment count for doctor ${doctorId} (${year}-${month}) by user ${req.user?.id || 'unknown'}`);
    
    // Check if user can access this doctor's data
    if (req.user.role === 'Doctor' && req.user.id !== doctorId) {
      return res.status(403).json({
        success: false,
        message: 'You can only view your own appointment count'
      });
    }
    
    const result = await appointmentService.getDoctorMonthlyAppointmentCount(
      doctorId, 
      parseInt(year), 
      parseInt(month)
    );
    
    if (!result.success) {
      return res.status(400).json(result);
    }
    
    res.status(200).json(result);
  } catch (error) {
    logger.error('Error in getMonthlyAppointmentCount controller:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
}

/**
 * Get current month appointment count for a doctor
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
async function getCurrentMonthAppointmentCount(req, res) {
  try {
    const { doctorId } = req.params;
    
    // If no doctorId provided and user is a doctor, use their own ID
    let targetDoctorId = doctorId;
    if (!doctorId && req.user.role === 'Doctor') {
      targetDoctorId = req.user.id;
    }
    
    if (!targetDoctorId) {
      return res.status(400).json({
        success: false,
        message: 'Doctor ID is required'
      });
    }
    
    // Check if user can access this doctor's data
    if (req.user.role === 'Doctor' && req.user.id !== targetDoctorId) {
      return res.status(403).json({
        success: false,
        message: 'You can only view your own appointment count'
      });
    }
    
    logger.debug(`Getting current month appointment count for doctor ${targetDoctorId}`);
    
    const result = await appointmentService.getDoctorCurrentMonthAppointmentCount(targetDoctorId);
    
    if (!result.success) {
      return res.status(400).json(result);
    }
    
    res.status(200).json(result);
  } catch (error) {
    logger.error('Error in getCurrentMonthAppointmentCount controller:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
}

/**
 * Get my appointment count (for logged-in doctor)
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
async function getMyAppointmentCount(req, res) {
  try {
    // Only doctors can use this endpoint
    if (req.user.role !== 'Doctor') {
      return res.status(403).json({
        success: false,
        message: 'This endpoint is only available for doctors'
      });
    }
    
    const { year, month } = req.query;
    
    let result;
    if (year && month) {
      // Get specific month count
      result = await appointmentService.getDoctorMonthlyAppointmentCount(
        req.user.id, 
        parseInt(year), 
        parseInt(month)
      );
    } else {
      // Get current month count
      result = await appointmentService.getDoctorCurrentMonthAppointmentCount(req.user.id);
    }
    
    if (!result.success) {
      return res.status(400).json(result);
    }
    
    res.status(200).json(result);
  } catch (error) {
    logger.error('Error in getMyAppointmentCount controller:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
}
module.exports = {
  createAppointment,
  updateAppointment,
  getAppointments,
  getAppointmentById,
  cancelAppointment,
  getAppointmentsByView,
  getTodayAppointments,
  sendAppointmentReminders,
  getMonthlyAppointmentCount,        // ← Add this
  getCurrentMonthAppointmentCount,   // ← Add this
  getMyAppointmentCount, 
};