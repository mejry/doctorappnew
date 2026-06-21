const consultationService = require("../services/consultationService");
const {
  consultationValidationRules,
  filterValidationRules,
  updateConsultationRules,
  validate,
} = require("../validators/consultationValidator");
const logger = require("../utils/logger");

exports.createConsultation = [
  consultationValidationRules(),
  validate,
  async (req, res, next) => {
    try {
      // Extract the Authorization header to pass to the service
      const authToken = req.headers.authorization;

      const consultation = await consultationService.createConsultation(
        req.body,
        authToken,
      );
      logger.info(`Consultation created: ${consultation._id}`);
      res.status(201).json(consultation);
    } catch (error) {
      logger.error(`Create consultation error: ${error.message}`);
      next(error);
    }
  },
];

exports.getConsultationById = async (req, res, next) => {
  try {
    const consultation = await consultationService.getConsultationById(
      req.params.id,
    );
    if (!consultation) {
      return res.status(404).json({
        success: false,
        error: "Consultation not found",
      });
    }
    res.json(consultation);
  } catch (error) {
    next(error);
  }
};

exports.getConsultationsByPatient = async (req, res, next) => {
  try {
    const consultations = await consultationService.getConsultationsByPatient(
      req.params.patientId,
    );
    res.json(consultations);
  } catch (error) {
    next(error);
  }
};

exports.getAllConsultations = async (req, res, next) => {
  try {
    const consultations = await consultationService.getAllConsultations();
    res.json(consultations);
  } catch (error) {
    next(error);
  }
};

exports.updateConsultation = [
  updateConsultationRules(),
  validate,
  async (req, res, next) => {
    try {
      const consultation = await consultationService.updateConsultation(
        req.params.id,
        req.body,
      );
      if (!consultation) {
        return res.status(404).json({
          success: false,
          error: "Consultation not found",
        });
      }
      logger.info(`Consultation updated: ${consultation._id}`);
      res.json(consultation);
    } catch (error) {
      logger.error(`Update consultation error: ${error.message}`);
      next(error);
    }
  },
];

exports.deleteConsultation = async (req, res, next) => {
  try {
    console.log("🔥 DELETE HIT:", req.params.id);

    const result = await consultationService.deleteConsultation(req.params.id);

    console.log("DELETE RESULT:", result);

    if (!result) {
      return res.status(404).json({
        success: false,
        error: "Consultation not found",
      });
    }

    logger.info(`Consultation deleted: ${req.params.id}`);
    res.json({ success: true });
  } catch (error) {
    console.error("DELETE ERROR:", error);
    next(error);
  }
};

exports.searchConsultations = async (req, res, next) => {
  try {
    const consultations = await consultationService.searchConsultations(
      req.query.q,
    );
    res.json(consultations);
  } catch (error) {
    next(error);
  }
};

exports.filterConsultations = [
  filterValidationRules(),
  validate,
  async (req, res, next) => {
    try {
      const consultations = await consultationService.filterConsultations(
        req.query,
      );
      res.json(consultations);
    } catch (error) {
      next(error);
    }
  },
];

exports.exportConsultationAsPDF = async (req, res, next) => {
  try {
    const pdfBuffer = await consultationService.exportConsultationAsPDF(
      req.params.id,
    );

    res.set({
      "Content-Type": "application/pdf",
      "Content-Disposition": `attachment; filename=consultation-${req.params.id}.pdf`,
      "Content-Length": pdfBuffer.length,
    });

    res.send(pdfBuffer);
  } catch (error) {
    if (error.message === "Consultation not found") {
      return res.status(404).json({
        success: false,
        error: error.message,
      });
    }
    logger.error(`PDF export error: ${error.message}`);
    next(error);
  }
};
