// validators/patientValidator.js - VERSION CORRIGÉE POUR VOTRE MODÈLE IA
const { body, validationResult } = require('express-validator');

const patientValidationRules = () => [
  body('firstName').notEmpty().withMessage('First name is required'),
  body('lastName').notEmpty().withMessage('Last name is required'),
  body('email').isEmail().withMessage('Valid email is required'),
  body('gender').isIn(['Male', 'Female', 'Other']).withMessage('Invalid gender'),
  
  body('dob')
    .custom((value) => {
      const date = new Date(value);
      if (isNaN(date.getTime())) {
        throw new Error('Valid date of birth is required');
      }
      if (date > new Date()) {
        throw new Error('Date of birth cannot be in the future');
      }
      return true;
    }),
  
  body('phoneNumber')
    .optional({ values: 'falsy' })
    .custom((value) => {
      if (value && value.trim() !== '') {
        const phoneRegex = /^[+]?[\d\s\-\(\)]+$/;
        if (!phoneRegex.test(value)) {
          throw new Error('Valid phone number required');
        }
      }
      return true;
    }),

  body('civilStatus')
    .optional()
    .isIn(['Single', 'Married', 'Divorced', 'Widowed'])
    .withMessage('Invalid civil status'),
];

const medicalHistoryValidationRules = () => [
  body('patientId').notEmpty().withMessage('Patient ID is required'),
  
  body('bloodGlucoseLevel')
    .optional({ values: 'falsy' })
    .isFloat({ min: 0, max: 1000 })
    .withMessage('Invalid blood glucose level'),
  
  body('heartRate')
    .optional({ values: 'falsy' })
    .isInt({ min: 30, max: 300 })
    .withMessage('Invalid heart rate'),
  
  body('oxygenSaturation')
    .optional({ values: 'falsy' })
    .isInt({ min: 0, max: 100 })
    .withMessage('Invalid oxygen saturation'),
  
  // ✅ CORRECTION MAJEURE: Accepter Number ou String pour bloodPressure
  body('bloodPressure')
    .optional({ values: 'falsy' })
    .custom((value) => {
      if (value === null || value === undefined || value === '') return true;
      
      // Accepter les nombres (comme dans votre exemple: bloodPressure=118)
      if (typeof value === 'number') {
        if (value > 0 && value < 300) return true;
        throw new Error('Blood pressure number must be between 1 and 299');
      }
      
      // Accepter le format string "120/80"
      if (typeof value === 'string') {
        if (/^\d+\/\d+$/.test(value)) return true;
        throw new Error('Blood pressure string format should be: 120/80');
      }
      
      throw new Error('Blood pressure must be a number or string format "120/80"');
    }),
  
  body('respiratoryRate')
    .optional({ values: 'falsy' })
    .isInt({ min: 5, max: 60 })
    .withMessage('Invalid respiratory rate'),
  
  body('bodyTemperature')
    .optional({ values: 'falsy' })
    .isFloat({ min: 30, max: 45 })
    .withMessage('Invalid body temperature'),
  
  body('weight')
    .optional({ values: 'falsy' })
    .isFloat({ min: 1, max: 500 })
    .withMessage('Invalid weight'),
  
  body('height')
    .optional({ values: 'falsy' })
    .isFloat({ min: 30, max: 250 })
    .withMessage('Invalid height'),
  
  // ✅ CORRECTION MAJEURE: Validation flexible pour chronicDiseases
  body('chronicDiseases')
    .optional()
    .custom((value) => {
      if (value === null || value === undefined) return true;
      
      // Accepter les arrays (format normal Flutter)
      if (Array.isArray(value)) return true;
      
      // Accepter les strings (format modèle IA)
      if (typeof value === 'string') {
        // Valeurs autorisées pour le modèle IA
        const validValues = ['None', 'Hypertension', 'Diabetes', 'Asthma', 'Arthritis'];
        if (validValues.includes(value) || value.includes(',')) return true;
        throw new Error(`Chronic diseases string must be one of: ${validValues.join(', ')} or comma-separated list`);
      }
      
      throw new Error('Chronic diseases must be an array or valid string');
    }),
  
  // ✅ CORRECTION MAJEURE: Validation flexible pour allergies  
  body('allergies')
    .optional()
    .custom((value) => {
      if (value === null || value === undefined) return true;
      
      // Accepter les arrays (format normal Flutter)
      if (Array.isArray(value)) return true;
      
      // Accepter les strings (format modèle IA)
      if (typeof value === 'string') {
        if (value === 'None' || value.length > 0) return true;
        return true; // Accepter toute string non vide
      }
      
      throw new Error('Allergies must be an array or string');
    }),
  
  body('smokingStatus')
    .optional()
    .isIn(['Non-smoker', 'Ex-smoker', 'Smoker', 'Former smoker']) // ✅ Ajout "Former smoker"
    .withMessage('Invalid smoking status'),
  
  body('alcoholConsumption')
    .optional()
    .isIn(['Never', 'Occasionally', 'Regularly', 'No']) // ✅ Ajout "No"
    .withMessage('Invalid alcohol consumption'),
  
  body('currentMedications')
    .optional()
    .isArray()
    .withMessage('Current medications must be an array'),
];

const consultationValidationRules = () => [
  body('patientId').notEmpty().withMessage('Patient ID is required'),
  body('date').isISO8601().withMessage('Valid consultation date required'),
  body('time').notEmpty().withMessage('Consultation time is required'),
  body('type').isIn(['Check-up', 'Test', 'Consultation', 'Control', 'Follow-up', 'Emergency'])
    .withMessage('Invalid consultation type'),
  body('status').isIn(['Scheduled', 'Completed', 'Canceled', 'Waiting', 'In Progress'])
    .withMessage('Invalid consultation status'),
  
  body('symptoms')
    .isArray({ min: 1 })
    .withMessage('At least one symptom is required')
    .custom((symptoms) => {
      if (!symptoms.every(symptom => typeof symptom === 'string' && symptom.trim().length > 0)) {
        throw new Error('All symptoms must be non-empty strings');
      }
      return true;
    }),
  
  body('diagnosis')
    .isArray({ min: 1 })
    .withMessage('At least one diagnosis is required')
    .custom((diagnoses) => {
      if (!diagnoses.every(diag => typeof diag === 'string' && diag.trim().length > 0)) {
        throw new Error('All diagnoses must be non-empty strings');
      }
      return true;
    }),
  
  body('prescribedAnalyses')
    .optional()
    .isArray()
    .withMessage('Prescribed analyses must be an array'),
  
  body('notes').optional().isString().withMessage('Notes must be a string'),
  body('duration').optional().isInt({ min: 1 }).withMessage('Duration must be a positive integer'),
  body('isEmergency').optional().isBoolean().withMessage('isEmergency must be boolean'),
];

const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    console.log('❌ Validation errors:', errors.array()); // ✅ AJOUT: Debug
    return res.status(400).json({ 
      success: false,
      message: 'Validation failed',
      errors: errors.array() 
    });
  }
  next();
};

module.exports = {
  patientValidationRules,
  medicalHistoryValidationRules,
  consultationValidationRules,
  validate
};