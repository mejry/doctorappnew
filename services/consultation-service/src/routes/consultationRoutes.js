const express = require('express');
const router = express.Router();
const consultationController = require('../controllers/consultationController');
const auth = require('../middlewares/auth');
const { 
  hasPermission, 
  CONSULTATION, 
  CONSULTATION_FILTERS, 
  isStaff,
  isDoctor 
} = require('../middlewares/permission');
router.get('/internal/:id', consultationController.getConsultationById);

// Appliquer l'authentification et vérification staff à toutes les routes
router.use(auth.verifyToken);
router.use(isStaff);

// Routes de recherche et filtrage (BEFORE parameterized routes)
router.get('/search', 
  hasPermission(CONSULTATION.VIEW), 
  consultationController.searchConsultations);

router.get('/filter', 
  hasPermission(CONSULTATION.VIEW), 
  consultationController.filterConsultations);

router.get('/patient/:patientId', 
  hasPermission(CONSULTATION.VIEW), 
  consultationController.getConsultationsByPatient);

// Routes principales consultations
router.post('/', 
  hasPermission(CONSULTATION.CREATE), 
  consultationController.createConsultation);

router.get('/', 
  hasPermission(CONSULTATION.VIEW), 
  consultationController.getAllConsultations);

// Routes d'export (before general /:id route)
router.get('/:id/export', 
  isDoctor,
  hasPermission(CONSULTATION.EXPORT), 
  consultationController.exportConsultationAsPDF);

// General parameterized routes (AFTER specific routes)
router.get('/:id', 
  hasPermission(CONSULTATION.VIEW), 
  consultationController.getConsultationById);

router.put('/:id', 
  hasPermission(CONSULTATION.UPDATE), 
  consultationController.updateConsultation);

router.delete('/:id', 
  hasPermission(CONSULTATION.DELETE), 
  consultationController.deleteConsultation);

module.exports = router;