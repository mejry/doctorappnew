// appointment-service/src/services/emailService.js
const nodemailer = require('nodemailer');
const config = require('../config/config');
const logger = require('../config/logger');

// Email templates
const EMAIL_TEMPLATES = {
  CREATED: 'created',
  UPDATED: 'updated',
  CANCELLED: 'cancelled',
  REMINDER: 'reminder'
};

// Initialize mail transporter
let transporter = null;

// Setup mail transporter if email is enabled
if (config.email.enabled) {
  transporter = nodemailer.createTransport({
    service: config.email.service,
    auth: {
      user: config.email.auth.user,
      pass: config.email.auth.pass
    }
  });
}

/**
 * Get email template for appointment
 * @param {Object} appointment - The appointment object
 * @param {string} template - Template type
 * @returns {Object} - Email subject and body
 */
function getEmailTemplate(appointment, template) {
  const formattedDate = new Date(appointment.date).toLocaleDateString();
  
  switch (template) {
    case EMAIL_TEMPLATES.CREATED:
      return {
        subject: 'Your Appointment Has Been Scheduled',
        body: `Dear ${appointment.patientName},

Your appointment with Dr. ${appointment.doctorName} has been scheduled for ${formattedDate} at ${appointment.time}.

Appointment Type: ${appointment.type}
Duration: ${appointment.duration} minutes

Please arrive 15 minutes before your scheduled time. 
If you need to reschedule, please contact us as soon as possible.

Thank you,
The Medical Team`
      };
      
    case EMAIL_TEMPLATES.UPDATED:
      return {
        subject: 'Your Appointment Has Been Updated',
        body: `Dear ${appointment.patientName},

Your appointment with Dr. ${appointment.doctorName} has been updated.

New Details:
Date: ${formattedDate}
Time: ${appointment.time}
Type: ${appointment.type}
Duration: ${appointment.duration} minutes

Please arrive 15 minutes before your scheduled time.
If you need to reschedule, please contact us as soon as possible.

Thank you,
The Medical Team`
      };
      
    case EMAIL_TEMPLATES.CANCELLED:
      return {
        subject: 'Your Appointment Has Been Cancelled',
        body: `Dear ${appointment.patientName},

Your appointment with Dr. ${appointment.doctorName} scheduled for ${formattedDate} at ${appointment.time} has been cancelled.

Reason: ${appointment.cancellationReason || 'Not specified'}

Please contact us to schedule a new appointment if needed.

Thank you,
The Medical Team`
      };
      
    case EMAIL_TEMPLATES.REMINDER:
      return {
        subject: 'Reminder: Your Appointment Tomorrow',
        body: `Dear ${appointment.patientName},

This is a friendly reminder about your appointment with Dr. ${appointment.doctorName} tomorrow, ${formattedDate} at ${appointment.time}.

Appointment Type: ${appointment.type}
Duration: ${appointment.duration} minutes

Please arrive 15 minutes before your scheduled time.
If you need to reschedule, please contact us as soon as possible.

Thank you,
The Medical Team`
      };
      
    default:
      return {
        subject: 'Appointment Information',
        body: `Dear ${appointment.patientName},

This is regarding your appointment with Dr. ${appointment.doctorName} on ${formattedDate} at ${appointment.time}.

Please contact our office for more information.

Thank you,
The Medical Team`
      };
  }
}

/**
 * Send email
 * @param {string} to - Recipient email
 * @param {string} subject - Email subject
 * @param {string} text - Email body
 * @returns {boolean} - Success status
 */
async function sendEmail(to, subject, text) {
  if (!config.email.enabled || !transporter) {
    logger.warn('Email service not configured. Email not sent.');
    return false;
  }
  
  try {
    const mailOptions = {
      from: config.email.auth.user,
      to,
      subject,
      text
    };
    
    const info = await transporter.sendMail(mailOptions);
    logger.info(`Email sent: ${info.messageId}`);
    return true;
  } catch (error) {
    logger.error('Error sending email:', error);
    return false;
  }
}

/**
 * Send appointment created email
 * @param {Object} appointment - Appointment data
 * @returns {boolean} - Success status
 */
async function sendAppointmentCreatedEmail(appointment) {
  if (!appointment.patientContact?.email) {
    return false;
  }
  
  const { subject, body } = getEmailTemplate(appointment, EMAIL_TEMPLATES.CREATED);
  return await sendEmail(appointment.patientContact.email, subject, body);
}

/**
 * Send appointment updated email
 * @param {Object} appointment - Appointment data
 * @returns {boolean} - Success status
 */
async function sendAppointmentUpdatedEmail(appointment) {
  if (!appointment.patientContact?.email) {
    return false;
  }
  
  const { subject, body } = getEmailTemplate(appointment, EMAIL_TEMPLATES.UPDATED);
  return await sendEmail(appointment.patientContact.email, subject, body);
}

/**
 * Send appointment cancelled email
 * @param {Object} appointment - Appointment data
 * @returns {boolean} - Success status
 */
async function sendAppointmentCancelledEmail(appointment) {
  if (!appointment.patientContact?.email) {
    return false;
  }
  
  const { subject, body } = getEmailTemplate(appointment, EMAIL_TEMPLATES.CANCELLED);
  return await sendEmail(appointment.patientContact.email, subject, body);
}

/**
 * Send appointment reminder email
 * @param {Object} appointment - Appointment data
 * @returns {boolean} - Success status
 */
async function sendAppointmentReminderEmail(appointment) {
  if (!appointment.patientContact?.email) {
    return false;
  }
  
  const { subject, body } = getEmailTemplate(appointment, EMAIL_TEMPLATES.REMINDER);
  return await sendEmail(appointment.patientContact.email, subject, body);
}

module.exports = {
  sendAppointmentCreatedEmail,
  sendAppointmentUpdatedEmail,
  sendAppointmentCancelledEmail,
  sendAppointmentReminderEmail
};