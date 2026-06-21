

// routes/medicationRoutes.js
const express = require('express');
const router = express.Router();
const medicationController = require('../controllers/medicationController');
const auth = require('../middlewares/auth');
const { 
  hasPermission, 
  MEDICATION,
  isStaff 
} = require('../middlewares/permission');

// Appliquer l'authentification à toutes les routes
router.use(auth.verifyToken);
router.use(isStaff);

// Routes medications avec permissions
router.post('/',  
  hasPermission(MEDICATION.CREATE), 
  medicationController.createMedication);

router.get('/', 
  hasPermission(MEDICATION.VIEW), 
  medicationController.getAllMedications);

router.get('/search', 
  hasPermission(MEDICATION.SEARCH), 
  medicationController.searchMedications);

router.get('/:id', 
  hasPermission(MEDICATION.VIEW), 
  medicationController.getMedicationById);

router.put('/:id', 
  hasPermission(MEDICATION.UPDATE), 
  medicationController.updateMedication);

router.delete('/:id', 
  hasPermission(MEDICATION.DELETE), 
  medicationController.deleteMedication);

module.exports = router;