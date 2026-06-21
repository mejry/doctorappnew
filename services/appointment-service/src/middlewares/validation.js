// appointment-service/src/middlewares/validation.js
const Joi = require('joi');
const logger = require('../config/logger');

/**
 * Validate appointment creation request
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 * @param {Function} next - Express next middleware function
 */
function validateCreateAppointment(req, res, next) {
  const schema = Joi.object({
    patientName: Joi.string().trim().required().messages({
      'string.empty': 'Patient name is required',
      'any.required': 'Patient name is required'
    }),
    patientContact: Joi.object({
      email: Joi.string().email().allow(null, ''),
      phone: Joi.string().allow(null, '')
    }),
    doctorId: Joi.string().required().messages({
      'string.empty': 'Doctor ID is required',
      'any.required': 'Doctor ID is required'
    }),
    doctorName: Joi.string().trim().required().messages({
      'string.empty': 'Doctor name is required',
      'any.required': 'Doctor name is required'
    }),
    date: Joi.date().iso().required().messages({
      'date.base': 'Date must be a valid date',
      'any.required': 'Date is required'
    }),
    time: Joi.string().pattern(/^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$/).required().messages({
      'string.pattern.base': 'Time must be in HH:MM format',
      'any.required': 'Time is required'
    }),
    type: Joi.string().valid('Consultation', 'Follow-up', 'Emergency', 'Test', 'Procedure').required().messages({
      'any.only': 'Type must be one of: Consultation, Follow-up, Emergency, Test, Procedure',
      'any.required': 'Type is required'
    }),
    duration: Joi.number().integer().min(5).default(30).messages({
      'number.base': 'Duration must be a number',
      'number.min': 'Duration must be at least 5 minutes'
    }),
    notes: Joi.string().allow(null, '')
  });
  
  const { error, value } = schema.validate(req.body, { abortEarly: false });
  
  if (error) {
    const errors = error.details.map(detail => detail.message);
    
    logger.debug('Appointment validation failed:', errors);
    
    return res.status(400).json({
      success: false,
      message: 'Validation failed',
      errors
    });
  }
  
  // Add createdBy field if user exists in request
  if (req.user) {
    value.createdBy = req.user.id;
  }
  
  // Update request body with validated values
  req.body = value;
  next();
}

/**
 * Validate appointment update request
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 * @param {Function} next - Express next middleware function
 */
function validateUpdateAppointment(req, res, next) {
  const schema = Joi.object({
    patientName: Joi.string().trim(),
    patientContact: Joi.object({
      email: Joi.string().email().allow(null, ''),
      phone: Joi.string().allow(null, '')
    }),
    doctorId: Joi.string(),
    doctorName: Joi.string().trim(),
    date: Joi.date().iso().messages({
      'date.base': 'Date must be a valid date'
    }),
    time: Joi.string().pattern(/^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$/).messages({
      'string.pattern.base': 'Time must be in HH:MM format'
    }),
    type: Joi.string().valid('Consultation', 'Follow-up', 'Emergency', 'Test', 'Procedure').messages({
      'any.only': 'Type must be one of: Consultation, Follow-up, Emergency, Test, Procedure'
    }),
    duration: Joi.number().integer().min(5).messages({
      'number.base': 'Duration must be a number',
      'number.min': 'Duration must be at least 5 minutes'
    }),
    status: Joi.string().valid('Scheduled', 'Checked-in', 'In-progress', 'Completed', 'Cancelled', 'No-show').messages({
      'any.only': 'Status must be one of: Scheduled, Checked-in, In-progress, Completed, Cancelled, No-show'
    }),
    notes: Joi.string().allow(null, ''),
    cancellationReason: Joi.string().when('status', {
      is: 'Cancelled',
      then: Joi.string().required().messages({
        'any.required': 'Cancellation reason is required when status is Cancelled'
      }),
      otherwise: Joi.string().allow(null, '')
    })
  }).min(1).messages({
    'object.min': 'At least one field must be provided for update'
  });
  
  const { error, value } = schema.validate(req.body, { abortEarly: false });
  
  if (error) {
    const errors = error.details.map(detail => detail.message);
    
    logger.debug('Appointment update validation failed:', errors);
    
    return res.status(400).json({
      success: false,
      message: 'Validation failed',
      errors
    });
  }
  
  // Add updatedBy field if user exists in request
  if (req.user) {
    value.updatedBy = req.user.id;
  }
  
  // Update request body with validated values
  req.body = value;
  next();
}

/**
 * Validate appointment cancellation request
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 * @param {Function} next - Express next middleware function
 */
function validateCancelAppointment(req, res, next) {
  const schema = Joi.object({
    cancellationReason: Joi.string().trim().required().messages({
      'string.empty': 'Cancellation reason is required',
      'any.required': 'Cancellation reason is required'
    })
  });
  
  const { error, value } = schema.validate(req.body, { abortEarly: false });
  
  if (error) {
    const errors = error.details.map(detail => detail.message);
    
    logger.debug('Appointment cancellation validation failed:', errors);
    
    return res.status(400).json({
      success: false,
      message: 'Validation failed',
      errors
    });
  }
  
  // Add updatedBy field if user exists in request
  if (req.user) {
    value.updatedBy = req.user.id;
  }
  
  // Update request body with validated values
  req.body = value;
  next();
}
function validateCheckIn(req, res, next) {
  const schema = Joi.object({
    notes: Joi.string().allow('', null),
    priority: Joi.string().valid('Low', 'Normal', 'High', 'Emergency').default('Normal'),
    priorityReason: Joi.string().when('priority', {
      is: Joi.valid('High', 'Emergency'),
      then: Joi.string().required(),
      otherwise: Joi.string().allow('', null)
    })
  });
  
  const { error, value } = schema.validate(req.body);
  
  if (error) {
    return res.status(400).json({
      success: false,
      message: 'Validation failed',
      errors: error.details.map(detail => detail.message)
    });
  }
  
  req.body = value;
  next();
}

/**
 * Validate no-show request
 */
function validateNoShow(req, res, next) {
  const schema = Joi.object({
    reason: Joi.string().required().messages({
      'string.empty': 'Reason for no-show is required',
      'any.required': 'Reason for no-show is required'
    })
  });
  
  const { error, value } = schema.validate(req.body);
  
  if (error) {
    return res.status(400).json({
      success: false,
      message: 'Validation failed',
      errors: error.details.map(detail => detail.message)
    });
  }
  
  req.body = value;
  next();
}

/**
 * Validate complete consultation request
 */
function validateCompleteConsultation(req, res, next) {
  const schema = Joi.object({
    notes: Joi.string().allow('', null),
    actualDuration: Joi.number().integer().min(1).max(300).messages({
      'number.min': 'Duration must be at least 1 minute',
      'number.max': 'Duration cannot exceed 300 minutes'
    })
  });
  
  const { error, value } = schema.validate(req.body);
  
  if (error) {
    return res.status(400).json({
      success: false,
      message: 'Validation failed',
      errors: error.details.map(detail => detail.message)
    });
  }
  
  req.body = value;
  next();
}

/**
 * Validate priority update request
 */
function validatePriorityUpdate(req, res, next) {
  const schema = Joi.object({
    priority: Joi.string().valid('Low', 'Normal', 'High', 'Emergency').required(),
    reason: Joi.string().when('priority', {
      is: Joi.valid('High', 'Emergency'),
      then: Joi.string().required(),
      otherwise: Joi.string().allow('', null)
    })
  });
  
  const { error, value } = schema.validate(req.body);
  
  if (error) {
    return res.status(400).json({
      success: false,
      message: 'Validation failed',
      errors: error.details.map(detail => detail.message)
    });
  }
  
  req.body = value;
  next();
}

/**
 * Validate delay notification request
 */
function validateDelayNotification(req, res, next) {
  const schema = Joi.object({
    delayMinutes: Joi.number().integer().min(1).max(180).required().messages({
      'number.min': 'Delay must be at least 1 minute',
      'number.max': 'Delay cannot exceed 180 minutes',
      'any.required': 'Delay minutes is required'
    }),
    reason: Joi.string().required().messages({
      'string.empty': 'Reason for delay is required',
      'any.required': 'Reason for delay is required'
    })
  });
  
  const { error, value } = schema.validate(req.body);
  
  if (error) {
    return res.status(400).json({
      success: false,
      message: 'Validation failed',
      errors: error.details.map(detail => detail.message)
    });
  }
  
  req.body = value;
  next();
}
module.exports = {
  validateCreateAppointment,
  validateUpdateAppointment,
  validateCancelAppointment,
  validateCheckIn,
  validateNoShow,
  validateCompleteConsultation,
  validatePriorityUpdate,
  validateDelayNotification
};