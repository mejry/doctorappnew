const { body, validationResult } = require('express-validator');

exports.medicationValidationRules = () => [
  body('identification.name').notEmpty(),
  body('pharmaceuticalProperties.form').isIn([
    'Tablet', 'Capsule', 'Solution', 'Injection', 
    'Cream', 'Suppository', 'Suspension', 'Aerosol',
    'Powder', 'Patch', 'Drops', 'Other'
  ]),
 body('dosage.standard.adult.dose').notEmpty(),
  body('safety.pregnancy.category').isIn(['A', 'B', 'C', 'D', 'X'])
];

exports.updateMedicationRules = () => [
  body('identification.name').optional().notEmpty(),
  body('inventory.currentStock').optional().isInt({ min: 0 }),
  body('inventory.status').optional().isIn(['In Stock', 'Low Stock', 'Out of Stock', 'Discontinued'])
];

exports.validate = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }
  next();
};