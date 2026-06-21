const patientService = require("../services/patientService");
const {
  patientValidationRules,
  medicalHistoryValidationRules,
  validate,
} = require("../validators/patientValidator");

exports.createPatient = [
  patientValidationRules(),
  validate,
  async (req, res, next) => {
    try {
      const patient = await patientService.createPatient(req.body);
      res.status(201).json(patient);
    } catch (error) {
      next(error);
    }
  },
];

// patientController.js
exports.getCurrentMonthPatientCount = async (req, res, next) => {
  try {
    const count = await patientService.getCurrentMonthPatientCount();
    res.json({
      success: true,
      count,
      month: new Date().toLocaleString("default", { month: "long" }),
      year: new Date().getFullYear(),
    });
  } catch (error) {
    next(error);
  }
};

exports.getAllPatients = async (req, res, next) => {
  try {
    const patients = await patientService.getAllPatients();
    res.json(patients);
  } catch (error) {
    next(error);
  }
};

exports.getPatientById = async (req, res, next) => {
  try {
    const patient = await patientService.getPatientById(req.params.id);
    res.json(patient);
  } catch (error) {
    next(error);
  }
};

exports.updatePatient = async (req, res, next) => {
  try {
    const patient = await patientService.updatePatient(req.params.id, req.body);
    res.json(patient);
  } catch (error) {
    next(error);
  }
};

// exports.syncAllPatients = async (req, res, next) => {
//   try {
//     await patientService.syncAllPatients();
//     res.json({ success: true });
//   } catch (error) {
//     next(error);
//   }
// };

exports.deletePatient = async (req, res, next) => {
  try {
    const result = await patientService.deletePatient(req.params.id);
    res.json({ success: result });
  } catch (error) {
    next(error);
  }
};

exports.addMedicalHistory = [
  medicalHistoryValidationRules(),
  validate,
  async (req, res, next) => {
    try {
      const history = await patientService.addMedicalHistory(
        req.params.patientId,
        req.body,
      );
      res.status(201).json(history);
    } catch (error) {
      next(error);
    }
  },
];

exports.getMedicalHistoryByPatientId = async (req, res, next) => {
  try {
    const history = await patientService.getMedicalHistoryByPatientId(
      req.params.patientId,
    );
    res.json(history);
  } catch (error) {
    next(error);
  }
};

exports.updateMedicalHistory = async (req, res, next) => {
  try {
    const history = await patientService.updateMedicalHistory(
      req.params.id,
      req.body,
    );
    res.json(history);
  } catch (error) {
    next(error);
  }
};

exports.deleteMedicalHistory = async (req, res, next) => {
  try {
    const result = await patientService.deleteMedicalHistory(req.params.id);
    res.json({ success: result });
  } catch (error) {
    next(error);
  }
};

exports.searchPatients = async (req, res, next) => {
  try {
    const patients = await patientService.searchPatients(req.query);
    res.json(patients);
  } catch (error) {
    next(error);
  }
};

exports.filterPatients = async (req, res, next) => {
  try {
    const patients = await patientService.filterPatients(req.query);
    res.json(patients);
  } catch (error) {
    next(error);
  }
};

exports.searchMedicalHistory = async (req, res, next) => {
  try {
    const history = await patientService.searchMedicalHistory(
      req.params.patientId,
      req.query,
    );
    res.json(history);
  } catch (error) {
    next(error);
  }
};
