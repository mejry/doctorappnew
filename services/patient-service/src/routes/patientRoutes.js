
const express = require('express');
const router = express.Router();
const patientController = require('../controllers/patientController');
const auth = require('../middlewares/auth');
const { hasPermission, PATIENT, MEDICAL_HISTORY, isStaff } = require('../middlewares/permissions');
// ✅ ROUTES INTERNES POUR SERVICES (SANS AUTH) - PLACER EN PREMIER
router.get('/internal/:id', patientController.getPatientById);
router.get('/internal/:patientId/medical-history', patientController.getMedicalHistoryByPatientId);

// Appliquer l'authentification et vérification staff à toutes les routes
router.use(auth.verifyToken);
router.use(isStaff);

// Routes patients
router.get('/search', hasPermission(PATIENT.SEARCH), patientController.searchPatients);
router.get('/filter', hasPermission(PATIENT.VIEW), patientController.filterPatients);
router.post('/', hasPermission(PATIENT.CREATE), patientController.createPatient);
router.get('/', hasPermission(PATIENT.VIEW), patientController.getAllPatients);
router.get('/:id', hasPermission(PATIENT.VIEW), patientController.getPatientById);
router.put('/:id', hasPermission(PATIENT.UPDATE), patientController.updatePatient);
router.delete('/:id', hasPermission(PATIENT.DELETE), patientController.deletePatient);

// Routes historique médical
router.post('/:patientId/medical-history', 
  hasPermission(PATIENT.CREATE), 
  patientController.addMedicalHistory);

router.get('/:patientId/medical-history', 
  hasPermission(PATIENT.VIEW), 
  patientController.getMedicalHistoryByPatientId);

router.put('/medical-history/:id', 
  hasPermission(PATIENT.UPDATE), 
  patientController.updateMedicalHistory);

router.delete('/medical-history/:id', 
  hasPermission(PATIENT.DELETE), 
  patientController.deleteMedicalHistory);

router.get('/:patientId/medical-history/search', 
  hasPermission(PATIENT.VIEW), 
  patientController.searchMedicalHistory);

// Routes statistiques
// router.get('/stats/monthly-count', 
//   hasPermission(STATS.VIEW), 
//   patientController.getCurrentMonthPatientCount);

module.exports = router;