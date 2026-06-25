const { body, query, validationResult } = require('express-validator');

exports.prescriptionValidationRules = () => [
  // body('prescriber').notEmpty().isMongoId(),
  body('prescriptionInfo.type').isIn(['Regular', 'Emergency', 'Hospital', 'Discharge', 'Renewal']),
  body('prescriptionInfo.status').optional().isIn(['Active', 'Completed', 'Cancelled', 'Expired', 'Pending', 'Draft']),
  body('prescriptionInfo.date').isISO8601(),
  body('prescriptionInfo.time').matches(/^([01]\d|2[0-3]):([0-5]\d)$/),
  body('medications').isArray({ min: 1 }),
  
  // ✅ CORRECTION: Validation flexible pour medication OU customMedication
  body('medications.*.medication').optional().isMongoId(),
  body('medications.*.customMedication.name').optional().notEmpty(),
  
  // ✅ VALIDATION PERSONNALISÉE: Au moins un des deux doit être présent
  body('medications.*').custom((medication, { req, path }) => {
    if (!medication.medication && !medication.customMedication?.name) {
      throw new Error('Each medication must have either a medication ID or customMedication.name');
    }
    return true;
  }),
  
  // Validation des dosages (obligatoire pour tous)
  body('medications.*.dosage.strength').notEmpty(),
  body('medications.*.dosage.frequency').notEmpty(),
  body('medications.*.dosage.duration').notEmpty(),
  body('prescriptionInfo.notes').optional({ nullable: true }).isString()
];

exports.updatePrescriptionRules = () => [
  body().custom((value, { req }) => {
    // Allow empty body for PATCH requests
    if (Object.keys(req.body).length === 0) {
      throw new Error('At least one field must be provided for update');
    }
    return true;
  }),
  body('prescriptionInfo.type').optional().isIn(['Regular', 'Emergency', 'Hospital', 'Discharge', 'Renewal']),
  body('prescriptionInfo.status').optional().isIn(['Active', 'Completed', 'Cancelled', 'Expired', 'Pending', 'Draft']),
  body('prescriptionInfo.date').optional().isISO8601(),
  body('prescriptionInfo.time').optional().matches(/^([01]\d|2[0-3]):([0-5]\d)$/),
  body('prescriptionInfo.validityDays').optional().isInt({ min: 1 }),
  body('prescriptionInfo.notes').optional({ nullable: true }).isString(),
  body('clinicalContext.diagnosis').optional({ nullable: true }).isString(),
  body('clinicalContext.icdCode').optional({ nullable: true }).isString(),
  body('clinicalContext.priority').optional().isIn(['Routine', 'Urgent', 'STAT']),
  body('pharmacy.dispensed').optional().isBoolean(),
  body('pharmacy.dispenseDate').optional().isISO8601(),
  body('medications').optional().isArray({ min: 0 }),
  
  // ✅ CORRECTION: Validation flexible pour update aussi
  body('medications.*.medication').optional().isMongoId(),
  body('medications.*.customMedication.name').optional().notEmpty(),
  
  // ✅ VALIDATION PERSONNALISÉE pour update
  body('medications.*').optional().custom((medication, { req, path }) => {
    if (medication && !medication.medication && !medication.customMedication?.name) {
      throw new Error('Each medication must have either a medication ID or customMedication.name');
    }
    return true;
  }),
  
  body('medications.*.dosage.strength').optional().notEmpty(),
  body('medications.*.dosage.frequency').optional().notEmpty(),
  body('medications.*.dosage.duration').optional().notEmpty(),
  body('medications.*.quantity.prescribed').optional().isInt({ min: 1 }),
  body('medications.*.quantity.dispensed').optional().isInt({ min: 0 }),
  body('medications.*.refills.allowed').optional().isInt({ min: 0 }),
  body('medications.*.refills.remaining').optional().isInt({ min: 0 })
];

exports.validate = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    console.log('❌ Erreurs de validation:', JSON.stringify(errors.array(), null, 2));
    return res.status(400).json({ errors: errors.array() });
  }
  next();
};