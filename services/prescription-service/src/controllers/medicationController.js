const medicationService = require('../services/medicationService');
const { 
  medicationValidationRules, 
  updateMedicationRules,
  validate 
} = require('../validators/medicationValidator');
const logger = require('../utils/logger');

exports.createMedication = [
  medicationValidationRules(),
  validate,
  async (req, res, next) => {
    try {
      const medication = await medicationService.createMedication(req.body);
      logger.info(`Medication created: ${medication._id}`);
      res.status(201).json(medication);
    } catch (error) {
      logger.error(`Create medication error: ${error.message}`);
      next(error);
    }
  }
];

exports.getMedicationById = async (req, res, next) => {
  try {
    const medication = await medicationService.getMedicationById(req.params.id);
    if (!medication) {
      return res.status(404).json({ error: 'Medication not found' });
    }
    res.json(medication);
  } catch (error) {
    next(error);
  }
};

exports.getAllMedications = async (req, res, next) => {
    try {
      const medications = await medicationService.getAllMedications();
      res.json(medications);
    } catch (error) {
      next(error);
    }
  };

exports.updateMedication = [
  updateMedicationRules(),
  validate,
  async (req, res, next) => {
    try {
      const medication = await medicationService.updateMedication(
        req.params.id, 
        req.body
      );
      if (!medication) {
        return res.status(404).json({ error: 'Medication not found' });
      }
      logger.info(`Medication updated: ${medication._id}`);
      res.json(medication);
    } catch (error) {
      logger.error(`Update medication error: ${error.message}`);
      next(error);
    }
  }
];

exports.deleteMedication = async (req, res, next) => {
  try {
    const success = await medicationService.deleteMedication(req.params.id);
    if (!success) {
      return res.status(404).json({ error: 'Medication not found' });
    }
    logger.info(`Medication deleted: ${req.params.id}`);
    res.json({ success: true });
  } catch (error) {
    logger.error(`Delete medication error: ${error.message}`);
    next(error);
  }
};

exports.searchMedications = async (req, res, next) => {
    try {
      const query = req.query.q; // Récupère le paramètre de recherche
      if (!query) {
        return res.status(400).json({ error: 'Search query parameter "q" is required' });
      }
      
      const medications = await medicationService.searchMedications(query);
      res.json(medications);
    } catch (error) {
      next(error);
    }
 
};