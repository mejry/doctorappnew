const { body, query, validationResult } = require('express-validator');
exports.consultationValidationRules = () => [
  body('patientId').notEmpty().isMongoId(),
  body('date').isISO8601(),
  body('time').matches(/^([01]\d|2[0-3]):([0-5]\d)$/),
  body('type').isIn(['Bilan', 'Test', 'Consultation', 'Control', 'Follow-up', 'Emergency']),
  body('status').optional().isIn(['Scheduled', 'Completed', 'Canceled', 'Waiting', 'InProgress']),
  body('symptoms').isArray({ min: 1 }),
  body('diagnosis').isArray({ min: 1 }),
  //body('duration').optional().isInt({ min: 5, max: 240 })
];

exports.filterValidationRules = () => [
  query('patientId').optional().isMongoId(),
  query('status').optional().isIn(['Scheduled', 'Completed', 'Canceled', 'Waiting', 'InProgress']),
  query('type').optional().isIn(['Bilan', 'Test', 'Consultation', 'Control', 'Follow-up', 'Emergency']),
  query('dateFrom').optional().isISO8601(),
  query('dateTo').optional().isISO8601(),
  query('isEmergency').optional().isBoolean()
];

exports.validate = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }
  next();
};

exports.updateConsultationRules = () => [
  body('patientId').optional().isMongoId().withMessage('ID patient invalide'),
  body('date').optional().isISO8601().withMessage('Format date invalide (YYYY-MM-DD)'),
  body('time').optional().matches(/^([01]\d|2[0-3]):([0-5]\d)$/).withMessage('Format heure invalide (HH:MM)'),
  body('type').optional().isIn(['Bilan', 'Test', 'Consultation', 'Control', 'Follow-up', 'Emergency'])
    .withMessage('Type de consultation invalide'),
  body('status').optional().isIn(['Scheduled', 'Completed', 'Canceled', 'Waiting', 'InProgress'])
    .withMessage('Statut invalide'),
  body('symptoms').optional().isArray({ min: 1 }).withMessage('Au moins un symptôme requis'),
  body('diagnosis').optional().isArray({ min: 1 }).withMessage('Au moins un diagnostic requis'),
  body('duration').optional().isInt({ min: 5, max: 240 }).withMessage('Durée doit être entre 5 et 240 minutes')
];