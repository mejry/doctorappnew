
const prescriptionService = require('../services/prescriptionService');
const { 
  prescriptionValidationRules, 
  updatePrescriptionRules,
  validate 
} = require('../validators/prescriptionValidator');
const logger = require('../utils/logger');

exports.createPrescription = [
  prescriptionValidationRules(),
  validate,
  async (req, res, next) => {
    try {
      const prescription = await prescriptionService.createPrescription(req.body);
      logger.info(`Prescription created: ${prescription._id}`);
      res.status(201).json(prescription);
    } catch (error) {
      logger.error(`Create prescription error: ${error.message}`);
      next(error);
    }
  }
];


exports.getPrescriptionById = async (req, res, next) => {
  try {
    const prescription = await prescriptionService.getPrescriptionById(req.params.id);
    if (!prescription) {
      return res.status(404).json({ error: 'Prescription not found' });
    }
    res.json(prescription);
  } catch (error) {
    next(error);
  }
};


exports.getAISuggestions = async (req, res, next) => {
  try {
    const consultationId = req.params.consultationId;
    
    if (!consultationId) {
      return res.status(400).json({
        success: false,
        error: 'Consultation ID requis'
      });
    }

    console.log(`📋 Demande suggestions IA pour consultation: ${consultationId}`);
    
    const suggestions = await prescriptionService.getAISuggestions(consultationId);
    
    const response = {
      success: suggestions.success || false,
      consultationId: consultationId,
      suggestions: suggestions.predictions || [],
      ai_available: suggestions.success || false,
      processing_time: suggestions.processing_time || '0ms',
      total_medications: suggestions.predictions?.length || 0,
      error: suggestions.error || null
    };

    console.log(`✅ Réponse suggestions: ${response.total_medications} médicaments`);
    
    res.json(response);
    
  } catch (error) {
    logger.error(`AI suggestions controller error: ${error.message}`);
    res.status(500).json({
      success: false,
      error: 'Service IA temporairement indisponible',
      suggestions: [],
      ai_available: false
    });
  }
};


exports.getPrescriptionsByConsultation = async (req, res, next) => {
  try {
    const consultationId = req.params.consultationId;
    const prescriptions = await prescriptionService.getPrescriptionsByConsultation(consultationId);
    
    if (!prescriptions || prescriptions.length === 0) {
      return res.status(200).json([]); // Retourner tableau vide au lieu de 404
    }
    
    logger.info(`Retrieved ${prescriptions.length} prescriptions for consultation ${consultationId}`);
    res.json(prescriptions);
  } catch (error) {
    logger.error(`Get prescriptions by consultation error: ${error.message}`);
    next(error);
  }
};
exports.getAllPrescriptions = async (req, res, next) => {
  try {
    const prescriptions = await prescriptionService.getAllPrescriptions();
    res.json(prescriptions);
  } catch (error) {
    next(error);
  }
};

exports.updatePrescription = [
  updatePrescriptionRules(),
 validate,
  async (req, res, next) => {
    try {
      // Filter out undefined values to prevent overwriting with null
      const updateData = Object.fromEntries(
        Object.entries(req.body).filter(([_, v]) => v !== undefined)
      );
      
      const prescription = await prescriptionService.updatePrescription(
        req.params.id, 
        updateData
      );
      
      if (!prescription) {
        return res.status(404).json({ error: 'Prescription not found' });
      }
      
      logger.info(`Prescription updated: ${prescription._id}`);
      res.json(prescription);
    } catch (error) {
      logger.error(`Update prescription error: ${error.message}`);
      next(error);
    }
  }
];
exports.deletePrescription = async (req, res, next) => {
  try {
    const success = await prescriptionService.deletePrescription(req.params.id);
    if (!success) {
      return res.status(404).json({ error: 'Prescription not found' });
    }
    logger.info(`Prescription deleted: ${req.params.id}`);
    res.json({ success: true });
  } catch (error) {
    logger.error(`Delete prescription error: ${error.message}`);
    next(error);
  }
};

exports.exportPrescriptionAsPDF = async (req, res, next) => {
  try {
    const pdfBuffer = await prescriptionService.exportPrescriptionAsPDF(req.params.id);
    
    res.set({
      'Content-Type': 'application/pdf',
      'Content-Disposition': `attachment; filename=prescription-${req.params.id}.pdf`,
      'Content-Length': pdfBuffer.length
    });
    
    res.send(pdfBuffer);
  } catch (error) {
    if (error.message === 'Prescription not found') {
      return res.status(404).json({ error: error.message });
    }
    logger.error(`PDF export error: ${error.message}`);
    next(error);
  }
};



exports.searchPrescriptions = async (req, res, next) => {
  try {
    const prescriptions = await prescriptionService.searchPrescriptions(req.query.q);
    res.json(prescriptions);
  } catch (error) {
    next(error);
  }
};
