const nodemailer = require('nodemailer');
const logger = require('../utils/logger');
const path = require('path');
const dotenv = require('dotenv');

dotenv.config({ path: path.resolve(__dirname, '../config/.env') });

class EmailService {
  constructor() {
    this.transporter = nodemailer.createTransport({
      service: 'gmail',
      host: "smtp.gmail.com",
      port: 587,
      secure: false,
      auth: {
        user: process.env.EMAIL_USERNAME,
        pass: process.env.EMAIL_PASSWORD,
      },
    });
  }

 async sendPrescriptionEmail(patientEmail, patientName, prescriptionId) {
    try {
      // on part de __dirname = .../services
      const pdfFilePath = path.resolve(
        __dirname,
        '../../storage/prescription',
        prescriptionId,
        `prescription-${prescriptionId}.pdf`
      );

      // log pour debug
      console.log('PDF path used for email:', pdfFilePath);

      const mailOptions = {
        from: process.env.EMAIL_FROM,
        to: patientEmail,
        subject: 'Votre prescription médicale',
        html: `
          <h1>Bonjour ${patientName},</h1>
          <p>Veuillez trouver ci-joint votre prescription médicale.</p>
          <p>Cordialement,</p>
          <p>L'équipe médicale</p>
        `,
        attachments: [
          {
            filename: `prescription-${prescriptionId}.pdf`,
            path: pdfFilePath,
            contentType: 'application/pdf'
          }
        ]
      };

      const info = await this.transporter.sendMail(mailOptions);
      logger.info(`Email sent to ${patientEmail}`, {
        messageId: info.messageId,
        prescriptionId
      });
      return true;
    } catch (error) {
      logger.error('Failed to send prescription email', {
        error: error.message,
        patientEmail,
        prescriptionId
      });
      throw error;
    }
  }



}

module.exports = new EmailService();
