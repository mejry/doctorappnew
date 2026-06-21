// appointment-service/src/routes/appointmentRoutes.js
const express = require('express');
const router = express.Router();
const appointmentController = require('../controllers/appointmentController');
const validation = require('../middlewares/validation');
const auth = require('../middlewares/auth');
const permissions = require('../middlewares/permissionMiddleware');
const loggingMiddleware = require('../middlewares/loggingMiddleware');
const jwt = require('jsonwebtoken');
const config = require('../config/config');

// Apply authentication middleware to all routes
router.use(auth.verifyToken);
router.use(auth.isStaff);

// ================ DEBUG ROUTES ================

router.get('/debug/token', (req, res) => {
  const token = req.headers.authorization?.split(' ')[1];
  const decoded = jwt.decode(token);
  
  res.json({
    success: true,
    tokenReceived: !!token,
    decodedToken: decoded,
    extractedUser: req.user,
    userPermissions: req.user.permissions || [],
    userRole: req.user.role
  });
});

// ================ APPOINTMENT ROUTES ================

/**
 * CREATE APPOINTMENT
 * Required Permission: create_appointment
 * Allowed: Admin, Secretary, Receptionist
 * NOT Allowed: Doctor (doctors don't have create_appointment permission)
 */
router.post(
  '/',
  validation.validateCreateAppointment,
  permissions.hasPermission('create_appointment'), // ✅ Use YOUR permission
  loggingMiddleware.logAppointmentCreated,
  appointmentController.createAppointment
);

/**
 * GET ALL APPOINTMENTS
 * Required Permission: view_appointment
 * Allowed: All staff (Admin, Doctor, Secretary, Receptionist)
 * Doctors only see their own appointments due to filterByRole
 */
router.get(
  '/',
  permissions.hasPermission('view_appointment'), // ✅ Use YOUR permission
  permissions.filterByRole(), // Doctors automatically filtered to their own appointments
  loggingMiddleware.logAppointmentsRetrieved,
  appointmentController.getAppointments
);

/**
 * GET APPOINTMENT BY ID
 * Required Permission: view_appointment
 * Allowed: All staff
 * Doctors can only see their own appointments due to canAccessAppointment check
 */
router.get(
  '/:id',
  permissions.hasPermission('view_appointment'), // ✅ Use YOUR permission
  permissions.canAccessAppointment(), // Doctors can only access their own appointments
  loggingMiddleware.logAppointmentRetrieved,
  appointmentController.getAppointmentById
);

/**
 * UPDATE APPOINTMENT
 * Required Permission: update_appointment
 * Allowed: Admin, Doctor (own only), Secretary, Receptionist
 * Doctors can only update their own appointments
 */
router.put(
  '/:id',
  validation.validateUpdateAppointment,
  permissions.hasPermission('update_appointment'), // ✅ Use YOUR permission
  permissions.canAccessAppointment(), // Role-based access control
  loggingMiddleware.logAppointmentUpdated,
  appointmentController.updateAppointment
);

/**
 * CANCEL APPOINTMENT
 * Required Permission: cancel_appointment
 * Allowed: Admin, Doctor (own only), Secretary
 * NOT Allowed: Receptionist (they don't have cancel_appointment permission)
 * Doctors can only cancel their own appointments
 */
router.post(
  '/:id/cancel',
  validation.validateCancelAppointment,
  permissions.hasPermission('cancel_appointment'), // ✅ Use YOUR permission
  permissions.canAccessAppointment(), // Role-based access control
  loggingMiddleware.logAppointmentCancelled,
  appointmentController.cancelAppointment
);

/**
 * DELETE APPOINTMENT (Hard Delete - Admin only)
 * Required Permission: delete_user (only Admin has this permission)
 */
router.delete(
  '/:id',
  permissions.hasPermission('delete_user'), // Only Admin has this permission
  async (req, res) => {
    try {
      const { id } = req.params;
      
      const Appointment = require('../models/appointment');
      const appointment = await Appointment.findById(id);
      
      if (!appointment) {
        return res.status(404).json({
          success: false,
          message: 'Appointment not found'
        });
      }
      
      await Appointment.findByIdAndDelete(id);
      
      const logger = require('../config/logger');
      logger.info(`Appointment deleted: ID ${id} by user ${req.user.id} (${req.user.role})`);
      
      res.json({
        success: true,
        message: 'Appointment deleted successfully',
        deletedAppointment: {
          id: appointment._id,
          patientName: appointment.patientName,
          doctorName: appointment.doctorName,
          date: appointment.date,
          time: appointment.time
        }
      });
    } catch (error) {
      const logger = require('../config/logger');
      logger.error('Error deleting appointment:', error);
      
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: error.message
      });
    }
  }
);

/**
 * GET APPOINTMENTS BY VIEW (daily, weekly, monthly)
 * Required Permission: view_appointment
 * Doctors only see their own appointments
 */
router.get(
  '/view/:view',
  permissions.hasPermission('view_appointment'), // ✅ Use YOUR permission
  permissions.filterByRole(), // Apply role-based filtering
  loggingMiddleware.logAppointmentsRetrieved,
  appointmentController.getAppointmentsByView
);

/**
 * GET TODAY'S APPOINTMENTS (for waiting room)
 * Required Permission: view_appointment
 * Doctors only see their own appointments
 */
router.get(
  '/today',
  permissions.hasPermission('view_appointment'), // ✅ Use YOUR permission
  permissions.filterByRole(), // Apply role-based filtering
  loggingMiddleware.logAppointmentsRetrieved,
  appointmentController.getTodayAppointments
);

/**
 * SEND APPOINTMENT REMINDERS
 * Required Permission: view_logs (Admin/Secretary level permission)
 * Only Admin and users with view_logs permission can send reminders
 */
router.post(
  '/system/send-reminders',
  permissions.hasPermission('view_logs'), // Admin level operation
  loggingMiddleware.logRemindersSent,
  appointmentController.sendAppointmentReminders
);

/**
 * EXPORT APPOINTMENTS
 * Required Permission: view_logs (Admin level)
 */
router.get(
  '/system/export',
  permissions.hasPermission('view_logs'), // Admin level operation
  permissions.filterByRole(), // Apply role-based filtering if needed
  async (req, res) => {
    try {
      const appointmentService = require('../services/appointmentService');
      const filters = req.query;
      
      // Apply role-based filtering for doctors
      if (req.user.role === 'Doctor') {
        filters.doctorId = req.user.id;
      }
      
      const result = await appointmentService.getAppointments(filters);
      
      if (!result.success) {
        return res.status(400).json(result);
      }
      
      // Convert to CSV format
      const csv = result.appointments.map(apt => [
        apt.patientName,
        apt.doctorName,
        new Date(apt.date).toLocaleDateString(),
        apt.time,
        apt.type,
        apt.status,
        apt.notes || ''
      ].join(',')).join('\n');
      
      const header = 'Patient Name,Doctor Name,Date,Time,Type,Status,Notes\n';
      
      res.setHeader('Content-Type', 'text/csv');
      res.setHeader('Content-Disposition', 'attachment; filename=appointments.csv');
      res.send(header + csv);
      
    } catch (error) {
      res.status(500).json({
        success: false,
        message: 'Export failed',
        error: error.message
      });
    }
  }
);
/**
 * GET MY APPOINTMENT COUNT (Current logged-in doctor)
 * Required Permission: view_appointment
 * Allowed: Doctor only
 * Optional query params: year, month
 * If no year/month provided, returns current month count
 */
router.get(
  '/count/my',
  permissions.hasPermission('view_appointment'),
  appointmentController.getMyAppointmentCount
);

/**
 * GET DOCTOR'S CURRENT MONTH APPOINTMENT COUNT
 * Required Permission: view_appointment
 * Allowed: Admin, Secretary (all doctors), Doctor (own only)
 */
router.get(
  '/count/doctor/:doctorId/current',
  permissions.hasPermission('view_appointment'),
  appointmentController.getCurrentMonthAppointmentCount
);

/**
 * GET DOCTOR'S SPECIFIC MONTH APPOINTMENT COUNT
 * Required Permission: view_appointment
 * Allowed: Admin, Secretary (all doctors), Doctor (own only)
 * URL: /count/doctor/:doctorId/:year/:month
 * Example: /count/doctor/123/2024/5 (for May 2024)
 */
router.get(
  '/count/doctor/:doctorId/:year/:month',
  permissions.hasPermission('view_appointment'),
  appointmentController.getMonthlyAppointmentCount
);

module.exports = router;