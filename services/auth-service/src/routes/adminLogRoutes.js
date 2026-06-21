// auth-service/src/routes/adminLogRoutes.js
const express = require('express');
const router = express.Router();
const adminLogController = require('../controllers/adminLogController');
const { authenticate, authorize } = require('../middlewares/authMiddleware');

// All routes require authentication and admin access
router.use(authenticate);
router.use(authorize('view_logs'));

// Get logs with filtering
router.get('/', adminLogController.getLogs);

// Get log statistics
router.get('/stats', adminLogController.getLogStats);

// Get filter options for the logs UI
router.get('/filter-options', adminLogController.getLogFilterOptions);

// Export logs to CSV
router.get('/export', adminLogController.exportLogs);

// Get logs for specific user
router.get('/user/:userId', adminLogController.getUserLogs);

// Get logs for specific appointment
router.get('/appointment/:appointmentId', adminLogController.getAppointmentLogs);

module.exports = router;