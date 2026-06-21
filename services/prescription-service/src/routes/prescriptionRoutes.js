
// routes/prescriptionRoutes.js
const express = require('express');
const router = express.Router();
const prescriptionController = require('../controllers/prescriptionController');

const auth = require('../middlewares/auth');

const { 
  hasPermission, 
  PRESCRIPTION, 
  PRESCRIPTION_FILTERS,
  isStaff,
  isDoctor 
} = require('../middlewares/permission');

// Appliquer l'authentification à toutes les routes
router.use(auth.verifyToken);
router.use(isStaff);

// Routes principales prescriptions
router.post('/', 
  hasPermission(PRESCRIPTION.CREATE), 
  prescriptionController.createPrescription);

router.get('/', 
  hasPermission(PRESCRIPTION.VIEW), 
  prescriptionController.getAllPrescriptions);

  
  router.get('/consultation/:consultationId', 
  hasPermission(PRESCRIPTION.VIEW), 
  prescriptionController.getPrescriptionsByConsultation);

  router.get('/ai-suggestions/:consultationId', 
  hasPermission(PRESCRIPTION.VIEW), 
  prescriptionController.getAISuggestions);

router.get('/search', 
  hasPermission(PRESCRIPTION.SEARCH), 
  prescriptionController.searchPrescriptions);

router.get('/:id', 
  hasPermission(PRESCRIPTION.VIEW), 
  prescriptionController.getPrescriptionById);

router.put('/:id', 
  hasPermission(PRESCRIPTION.UPDATE), 
  prescriptionController.updatePrescription);

router.delete('/:id', 
  hasPermission(PRESCRIPTION.DELETE), 
  prescriptionController.deletePrescription);



// Routes d'export (accès restreint aux docteurs)
router.get('/:id/export', 
  isDoctor,
  hasPermission(PRESCRIPTION.EXPORT), 
  prescriptionController.exportPrescriptionAsPDF);

// Route d'envoi par email (accès restreint aux docteurs)
// router.post('/:id/send', 
//   isDoctor,
//   hasPermission(PRESCRIPTION.SEND_EMAIL), 
//   prescriptionController.sendPrescriptionByEmail);

module.exports = router;