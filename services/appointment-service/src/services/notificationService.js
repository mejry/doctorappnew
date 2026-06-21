// appointment-service/src/services/notificationService.js
const nodemailer = require("nodemailer");
const logger = require("../config/logger");

class NotificationService {
  constructor() {
    // Initialize email transporter
    this.emailTransporter = null;
    this.initializeEmailTransporter();
  }

  /**
   * Initialize email transporter
   */
  initializeEmailTransporter() {
    try {
      this.emailTransporter = nodemailer.createTransport({
        service: "gmail",
        auth: {
          user: process.env.EMAIL_USER || "mejriaziz917@gmail.com",
          pass: process.env.EMAIL_PASSWORD || "jhfduzeajhdsqygiaz",
        },
      });

      logger.info("Email transporter initialized successfully");
    } catch (error) {
      logger.error("Failed to initialize email transporter:", error);
    }
  }

  /**
   * Send delay notification to patient
   * DA-60004: Notify patients via SMS or email if appointment is delayed
   * @param {Object} options - Notification options
   * @returns {Object} Notification result
   */
  async sendDelayNotification(options) {
    const {
      patientName,
      email,
      phone,
      delayMinutes,
      reason,
      estimatedNewTime,
    } = options;

    try {
      logger.info(`Sending delay notification to ${patientName}`);

      const message = this.generateDelayMessage({
        patientName,
        delayMinutes,
        reason,
        estimatedNewTime,
      });

      let emailSent = false;
      let smsSent = false;

      // Try email first
      if (email && this.emailTransporter) {
        try {
          await this.sendEmail({
            to: email,
            subject: "Appointment Delay Notification",
            text: message.text,
            html: message.html,
          });
          emailSent = true;
          logger.info(`Delay email sent to ${patientName} at ${email}`);
        } catch (emailError) {
          logger.warn(`Failed to send delay email to ${email}:`, emailError);
        }
      }

      // For now, we'll focus on email notifications
      // SMS can be added later with Twilio integration
      if (phone && !emailSent) {
        logger.info(
          `SMS notification needed for ${phone} but SMS service not configured`
        );
        // TODO: Implement SMS with Twilio
      }

      if (emailSent) {
        return {
          success: true,
          method: "email",
          message: "Delay notification sent successfully",
        };
      } else {
        return {
          success: false,
          message:
            "No valid contact method available or email service unavailable",
        };
      }
    } catch (error) {
      logger.error("Error sending delay notification:", error);
      return {
        success: false,
        message: "Failed to send delay notification",
        error: error.message,
      };
    }
  }

  /**
   * Send appointment reminder
   * @param {Object} options - Reminder options
   * @returns {Object} Reminder result
   */
  async sendAppointmentReminder(options) {
    const {
      patientName,
      email,
      phone,
      appointmentDate,
      appointmentTime,
      doctorName,
      appointmentType,
    } = options;

    try {
      const message = this.generateReminderMessage({
        patientName,
        appointmentDate,
        appointmentTime,
        doctorName,
        appointmentType,
      });

      let emailSent = false;

      // Send email reminder
      if (email && this.emailTransporter) {
        try {
          await this.sendEmail({
            to: email,
            subject: "Appointment Reminder",
            text: message.text,
            html: message.html,
          });
          emailSent = true;
          logger.info(`Reminder email sent to ${patientName}`);
        } catch (emailError) {
          logger.warn(`Failed to send reminder email to ${email}:`, emailError);
        }
      }

      return {
        success: emailSent,
        method: emailSent ? "email" : "none",
        message: emailSent
          ? "Reminder sent successfully"
          : "Failed to send reminder",
      };
    } catch (error) {
      logger.error("Error sending appointment reminder:", error);
      return {
        success: false,
        message: "Failed to send reminder",
      };
    }
  }

  /**
   * Send waiting time update to patient
   * @param {Object} options - Update options
   * @returns {Object} Update result
   */
  async sendWaitingTimeUpdate(options) {
    const {
      patientName,
      email,
      phone,
      estimatedWaitingTime,
      position,
      message,
    } = options;

    try {
      const updateMessage = this.generateWaitingTimeMessage({
        patientName,
        estimatedWaitingTime,
        position,
        customMessage: message,
      });

      // For waiting time updates, prefer quick methods
      if (email && this.emailTransporter) {
        await this.sendEmail({
          to: email,
          subject: "Waiting Time Update",
          text: updateMessage.text,
          html: updateMessage.html,
        });

        return {
          success: true,
          method: "email",
          message: "Waiting time update sent via email",
        };
      }

      return {
        success: false,
        message: "No contact method available",
      };
    } catch (error) {
      logger.error("Error sending waiting time update:", error);
      return {
        success: false,
        message: "Failed to send waiting time update",
      };
    }
  }

  /**
   * Send email
   * @private
   */
  async sendEmail({ to, subject, text, html }) {
    if (!this.emailTransporter) {
      throw new Error("Email service not initialized");
    }

    const mailOptions = {
      from: `"Medical Center" <${
        process.env.EMAIL_USER || "mejriaziz917@gmail.com"
      }>`,
      to,
      subject,
      text,
      html,
    };

    const info = await this.emailTransporter.sendMail(mailOptions);
    logger.debug(`Email sent: ${info.messageId}`);
    return info;
  }

  /**
   * Generate delay notification message
   * @private
   */
  generateDelayMessage({
    patientName,
    delayMinutes,
    reason,
    estimatedNewTime,
  }) {
    const text = `Dear ${patientName},

We apologize for the inconvenience. Your appointment has been delayed by approximately ${delayMinutes} minutes.

Reason: ${reason}
New estimated time: ${estimatedNewTime}

Please remain in the waiting room or nearby. We will notify you when the doctor is ready.

Thank you for your patience.

Medical Center`;

    const html = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #d32f2f;">Appointment Delay Notification</h2>
        <p>Dear <strong>${patientName}</strong>,</p>
        
        <p>We apologize for the inconvenience. Your appointment has been delayed by approximately <strong>${delayMinutes} minutes</strong>.</p>
        
        <div style="background-color: #fff3cd; border: 1px solid #ffeaa7; padding: 15px; border-radius: 5px; margin: 15px 0;">
          <p><strong>Reason:</strong> ${reason}</p>
          <p><strong>New estimated time:</strong> ${estimatedNewTime}</p>
        </div>
        
        <p>Please remain in the waiting room or nearby. We will notify you when the doctor is ready.</p>
        
        <p>Thank you for your patience.</p>
        
        <footer style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee; color: #666;">
          <p>Medical Center<br>
          Contact us: <a href="tel:+1234567890">+1 (234) 567-890</a></p>
        </footer>
      </div>
    `;

    return { text, html };
  }

  /**
   * Generate reminder message
   * @private
   */
  generateReminderMessage({
    patientName,
    appointmentDate,
    appointmentTime,
    doctorName,
    appointmentType,
  }) {
    const text = `Dear ${patientName},

This is a reminder for your upcoming appointment:

Date: ${appointmentDate}
Time: ${appointmentTime}
Doctor: Dr. ${doctorName}
Type: ${appointmentType}

Please arrive 15 minutes early for check-in.

Medical Center`;

    const html = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #1976d2;">Appointment Reminder</h2>
        <p>Dear <strong>${patientName}</strong>,</p>
        
        <p>This is a reminder for your upcoming appointment:</p>
        
        <div style="background-color: #e3f2fd; border: 1px solid #90caf9; padding: 15px; border-radius: 5px; margin: 15px 0;">
          <p><strong>Date:</strong> ${appointmentDate}</p>
          <p><strong>Time:</strong> ${appointmentTime}</p>
          <p><strong>Doctor:</strong> Dr. ${doctorName}</p>
          <p><strong>Type:</strong> ${appointmentType}</p>
        </div>
        
        <p><strong>Please arrive 15 minutes early for check-in.</strong></p>
        
        <footer style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee; color: #666;">
          <p>Medical Center<br>
          Contact us: <a href="tel:+1234567890">+1 (234) 567-890</a></p>
        </footer>
      </div>
    `;

    return { text, html };
  }

  /**
   * Generate waiting time update message
   * @private
   */
  generateWaitingTimeMessage({
    patientName,
    estimatedWaitingTime,
    position,
    customMessage,
  }) {
    const text =
      customMessage ||
      `Dear ${patientName},

Waiting time update:
Position in queue: ${position}
Estimated waiting time: ${estimatedWaitingTime} minutes

We appreciate your patience.

Medical Center`;

    const html = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #388e3c;">Waiting Time Update</h2>
        <p>Dear <strong>${patientName}</strong>,</p>
        
        <div style="background-color: #e8f5e8; border: 1px solid #4caf50; padding: 15px; border-radius: 5px; margin: 15px 0;">
          <p><strong>Position in queue:</strong> ${position}</p>
          <p><strong>Estimated waiting time:</strong> ${estimatedWaitingTime} minutes</p>
        </div>
        
        <p>We appreciate your patience.</p>
        
        <footer style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee; color: #666;">
          <p>Medical Center</p>
        </footer>
      </div>
    `;

    return { text, html };
  }

  /**
   * Test email configuration
   * @returns {Boolean} Configuration status
   */
  async testEmailConfiguration() {
    try {
      if (!this.emailTransporter) {
        return false;
      }

      await this.emailTransporter.verify();
      logger.info("Email configuration verified successfully");
      return true;
    } catch (error) {
      logger.error("Email configuration test failed:", error);
      return false;
    }
  }
}

module.exports = new NotificationService();
