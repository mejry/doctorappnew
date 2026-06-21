// appointment-service/src/routes/waitingRoomRoutes.js
const express = require('express');
const router = express.Router();
const waitingRoomController = require('../controllers/waitingRoomController');
const auth = require('../middlewares/auth');

// Simple validation middleware (inline)
const validateCheckIn = (req, res, next) => {
  const { priority } = req.body;
  
  if (priority && !['Low', 'Normal', 'High', 'Emergency'].includes(priority)) {
    return res.status(400).json({
      success: false,
      message: 'Invalid priority. Must be Low, Normal, High, or Emergency'
    });
  }
  
  if ((priority === 'High' || priority === 'Emergency') && !req.body.priorityReason) {
    return res.status(400).json({
      success: false,
      message: 'Priority reason is required for High and Emergency priorities'
    });
  }
  
  next();
};

const validateNoShow = (req, res, next) => {
  if (!req.body.reason) {
    return res.status(400).json({
      success: false,
      message: 'Reason for no-show is required'
    });
  }
  next();
};

const validateCompleteConsultation = (req, res, next) => {
  const { actualDuration } = req.body;
  
  if (actualDuration && (actualDuration < 1 || actualDuration > 300)) {
    return res.status(400).json({
      success: false,
      message: 'Duration must be between 1 and 300 minutes'
    });
  }
  
  next();
};

const validatePriorityUpdate = (req, res, next) => {
  const { priority } = req.body;
  
  if (!priority || !['Low', 'Normal', 'High', 'Emergency'].includes(priority)) {
    return res.status(400).json({
      success: false,
      message: 'Valid priority is required (Low, Normal, High, Emergency)'
    });
  }
  
  if ((priority === 'High' || priority === 'Emergency') && !req.body.reason) {
    return res.status(400).json({
      success: false,
      message: 'Reason is required for High and Emergency priorities'
    });
  }
  
  next();
};

const validateDelayNotification = (req, res, next) => {
  const { delayMinutes, reason } = req.body;
  
  if (!delayMinutes || delayMinutes < 1 || delayMinutes > 180) {
    return res.status(400).json({
      success: false,
      message: 'Delay minutes must be between 1 and 180'
    });
  }
  
  if (!reason) {
    return res.status(400).json({
      success: false,
      message: 'Reason for delay is required'
    });
  }
  
  next();
};

// Simple auth middleware
const isStaff = (req, res, next) => {
  if (!req.user) {
    return res.status(401).json({ 
      success: false, 
      message: 'Authentication required' 
    });
  }
  
  const staffRoles = ['Doctor', 'Receptionist', 'Admin', 'Secretary'];
  
  if (!staffRoles.includes(req.user.role)) {
    return res.status(403).json({ 
      success: false, 
      message: 'Staff access required' 
    });
  }
  
  next();
};

const isReceptionistOrAdmin = (req, res, next) => {
  if (!req.user) {
    return res.status(401).json({ 
      success: false, 
      message: 'Authentication required' 
    });
  }
  
  if (!['Receptionist', 'Admin', 'Secretary'].includes(req.user.role)) {
    return res.status(403).json({ 
      success: false, 
      message: 'Receptionist, Secretary or Admin access required' 
    });
  }
  
  next();
};

const isDoctorOrAdmin = (req, res, next) => {
  if (!req.user) {
    return res.status(401).json({ 
      success: false, 
      message: 'Authentication required' 
    });
  }
  
  if (!['Doctor', 'Admin'].includes(req.user.role)) {
    return res.status(403).json({ 
      success: false, 
      message: 'Doctor or Admin access required' 
    });
  }
  
  next();
};

// Routes
// Get today's queue for a doctor
// DA-60000: Display list of patients with appointments today
router.get('/doctor/:doctorId/today', 
  auth.verifyToken,
  isStaff,
  waitingRoomController.getTodaysQueue
);

// Check in a patient  
// DA-60001: Allow reception staff to mark patient as "Checked-In"
router.post('/checkin/:appointmentId',
  auth.verifyToken,
  isReceptionistOrAdmin,
  validateCheckIn,
  waitingRoomController.checkInPatient
);

// Mark patient as no-show
// DA-60002: Allow marking patient as "No-Show"
router.post('/no-show/:appointmentId',
  auth.verifyToken,
  isReceptionistOrAdmin,
  validateNoShow,
  waitingRoomController.markNoShow
);

// Start consultation
router.post('/start-consultation/:appointmentId',
  auth.verifyToken,
  isDoctorOrAdmin,
  waitingRoomController.startConsultation
);

// Complete consultation
// DA-60003: Allow doctor to mark consultation as "Completed"
router.post('/complete-consultation/:appointmentId',
  auth.verifyToken,
  isDoctorOrAdmin,
  validateCompleteConsultation,
  waitingRoomController.completeConsultation
);

// Update patient priority
// DA-60005: Allow prioritizing patients in emergencies
router.put('/priority/:appointmentId',
  auth.verifyToken,
  isReceptionistOrAdmin,
  validatePriorityUpdate,
  waitingRoomController.updatePatientPriority
);

// Get waiting time estimate for specific patient
// DA-60006: Display expected waiting time for each patient
router.get('/estimate/:appointmentId',
  auth.verifyToken,
  waitingRoomController.getWaitingTimeEstimate
);

// Send delay notifications
// DA-60004: Notify patients if appointment is delayed
router.post('/delay-notification/:doctorId',
  auth.verifyToken,
  isReceptionistOrAdmin,
  validateDelayNotification,
  waitingRoomController.sendDelayNotifications
);

// Get queue statistics
router.get('/statistics/:doctorId',
  auth.verifyToken,
  isDoctorOrAdmin,
  waitingRoomController.getQueueStatistics
);

module.exports = router;