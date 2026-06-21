// utils/email.js
const nodemailer = require('nodemailer');
const { rabbitMQ } = require('./rabbitmq');

// Create reusable transporter
let transporter;

// Initialize email transporter
const initTransporter = () => {
  if (transporter) return transporter;
  
  // Create transporter with environment variables
  transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
      user: 'mejriaziz917@gmail.com',
      pass: 'ceuxvddllkorhefy'
    },
    // Enable TLS security
    secure: true,
    // Add timeout
    connectionTimeout: 5000,
    // Verify connection on startup
    pool: true,
    maxConnections: 5
  });
  
  return transporter;
};

// Email templates
const templates = {
  welcome: (user) => ({
    subject: 'Welcome to Medical System',
    text: `Hello ${user.firstname}, welcome to our Medical System!`,
    html: `<h1>Welcome, ${user.firstname}!</h1><p>Your account has been created successfully.</p>`
  }),
  // ✅ ADD this to your existing templates object:
  passwordChanged: (data) => ({
    subject: 'Password Changed Successfully - Medical System',
    text: `Hello ${data.name},\n\nYour password has been successfully changed on ${data.timestamp}.\n\nIf you did not make this change, please contact support immediately.\n\nFor security reasons, you will need to log in again with your new password.`,
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
        <h2 style="color: #28a745; text-align: center;">✅ Password Changed Successfully</h2>
        <p>Hello <strong>${data.name}</strong>,</p>
        <p>Your password has been successfully changed.</p>
        
        <div style="background-color: #d4edda; border: 1px solid #c3e6cb; border-radius: 4px; padding: 15px; margin: 20px 0;">
          <h4 style="color: #155724; margin: 0 0 10px 0;">📋 Change Details</h4>
          <ul style="color: #155724; margin: 0; padding-left: 20px;">
            <li><strong>Account:</strong> ${data.email}</li>
            <li><strong>Date & Time:</strong> ${data.timestamp}</li>
            <li><strong>Action:</strong> Password changed by user</li>
          </ul>
        </div>

        <div style="background-color: #fff3cd; border: 1px solid #ffeaa7; border-radius: 4px; padding: 15px; margin: 20px 0;">
          <h4 style="color: #856404; margin: 0 0 10px 0;">🔐 Security Notice</h4>
          <p style="color: #856404; margin: 0;">
            For security reasons, you will need to log in again with your new password.
          </p>
        </div>

        <div style="text-align: center; margin: 30px 0;">
          <a href="${process.env.CLIENT_URL || 'http://localhost:3000'}/login" 
             style="background-color: #007bff; color: white; padding: 12px 24px; text-decoration: none; border-radius: 4px; display: inline-block;">
            Login Now
          </a>
        </div>

        <div style="background-color: #f8d7da; border: 1px solid #f5c6cb; border-radius: 4px; padding: 15px; margin: 20px 0;">
          <h4 style="color: #721c24; margin: 0 0 10px 0;">⚠️ Didn't Make This Change?</h4>
          <p style="color: #721c24; margin: 0;">
            If you did not change your password, your account may be compromised. 
            Please contact our support team immediately at 
            <a href="mailto:support@medical-system.com" style="color: #721c24;">support@medical-system.com</a>
          </p>
        </div>

        <hr style="margin: 30px 0; border: none; border-top: 1px solid #eee;">
        <p style="color: #999; font-size: 12px; text-align: center;">
          This is an automated security notification from the Medical System. Please do not reply to this email.
        </p>
      </div>
    `
  }),
  
  // ✅ NEW: Template for sending new password
  newPassword: (data) => ({
    subject: 'Your New Password - Medical System',
    text: `Hello ${data.name},\n\nYour password has been reset. Your new password is: ${data.newPassword}\n\nFor security reasons, please log in and change this password immediately.\n\nIf you didn't request this password reset, please contact support immediately.`,
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
        <h2 style="color: #333; text-align: center;">Password Reset - Medical System</h2>
        <p>Hello <strong>${data.name}</strong>,</p>
        <p>Your password has been successfully reset. Here is your new password:</p>
        
        <div style="background-color: #f8f9fa; border: 2px solid #007bff; border-radius: 8px; padding: 20px; text-align: center; margin: 20px 0;">
          <h3 style="color: #007bff; margin: 0 0 10px 0;">Your New Password</h3>
          <div style="background-color: #ffffff; border-radius: 4px; padding: 15px; font-family: 'Courier New', monospace; font-size: 18px; font-weight: bold; color: #333; letter-spacing: 2px;">
            ${data.newPassword}
          </div>
        </div>

        <div style="background-color: #fff3cd; border: 1px solid #ffeaa7; border-radius: 4px; padding: 15px; margin: 20px 0;">
          <h4 style="color: #856404; margin: 0 0 10px 0;">⚠️ Important Security Notice</h4>
          <ul style="color: #856404; margin: 0; padding-left: 20px;">
            <li>Please log in immediately and change this password</li>
            <li>Do not share this password with anyone</li>
            <li>Choose a strong, unique password when you change it</li>
          </ul>
        </div>

        <div style="text-align: center; margin: 30px 0;">
          <a href="${process.env.CLIENT_URL || 'http://localhost:3000'}/login" 
             style="background-color: #007bff; color: white; padding: 12px 24px; text-decoration: none; border-radius: 4px; display: inline-block;">
            Login Now
          </a>
        </div>

        <p style="color: #666; font-size: 14px;">
          If you didn't request this password reset, please contact our support team immediately at 
          <a href="mailto:support@medical-system.com">support@medical-system.com</a>
        </p>

        <hr style="margin: 30px 0; border: none; border-top: 1px solid #eee;">
        <p style="color: #999; font-size: 12px; text-align: center;">
          This is an automated message from the Medical System. Please do not reply to this email.
        </p>
      </div>
    `
  }),
  
  twoFactorCode: (code) => ({
    subject: 'Your Authentication Code',
    text: `Your verification code is: ${code}`,
    html: `<h2>Two-Factor Authentication</h2>
           <p>Your verification code is:</p>
           <h1 style="font-size: 24px; background-color: #f0f0f0; padding: 10px; text-align: center;">${code}</h1>
           <p>This code will expire in 10 minutes.</p>`
  })
};

// Add error handling and retry logic for email sending
const sendMailWithRetry = async (transport, mailOptions, retries = 3) => {
  try {
    return await transport.sendMail(mailOptions);
  } catch (error) {
    if (retries <= 0) throw error;
    console.log(`Email send failed, retrying... (${retries} attempts left)`);
    // Wait a bit before retrying
    await new Promise(resolve => setTimeout(resolve, 1000));
    return sendMailWithRetry(transport, mailOptions, retries - 1);
  }
};

module.exports = {
  // Initialize email service
  init: () => {
    return initTransporter();
  },
  
  // Send email with template
  sendTemplatedEmail: async (to, templateName, data, tokenData = null) => {
    try {
      const transport = initTransporter();
      
      if (!templates[templateName]) {
        throw new Error(`Template '${templateName}' not found`);
      }
      
      const { subject, text, html } = templates[templateName](data);
      
      const mailOptions = {
        from: `"Medical System" <mejriaziz917@gmail.com>`,
        to,
        subject,
        text,
        html
      };

      // Send email with retry
      const info = await sendMailWithRetry(transport, mailOptions);
      
      console.log(`Email sent successfully to ${to}, template: ${templateName}`);
      
      // Send to RabbitMQ if token data provided
      if (tokenData) {
        try {
          await rabbitMQ.publish('auth-events', {
            type: 'email_sent',
            data: {
              email: to,
              template: templateName,
              tokenData
            }
          });
        } catch (rmqError) {
          console.error('Failed to publish email event to RabbitMQ:', rmqError);
          // Don't fail the whole process if RabbitMQ fails
        }
      }
      
      return info;
    } catch (error) {
      console.error('Email sending failed:', error);
      
      // For testing: return success instead of throwing
      // Remove this in production
      console.log('DEVELOPMENT MODE: Simulating email success despite error');
      return { 
        messageId: 'mock-id',
        response: 'Mock success (email not actually sent)',
        mock: true,
        originalError: error.message
      };
      
      // Uncomment this for production:
      // throw error;
    }
  },
  
  // Send custom email
  sendEmail: async (to, subject, text, html, tokenData = null) => {
    try {
      const transport = initTransporter();
      
      const mailOptions = {
        from: `"Medical System" <mejriaziz917@gmail.com>`,
        to,
        subject,
        text,
        html: html || `<p>${text}</p>`
      };

      // Send email with retry
      const info = await sendMailWithRetry(transport, mailOptions);
      
      console.log(`Custom email sent successfully to ${to}`);
      
      // Send to RabbitMQ if token data provided
      if (tokenData) {
        try {
          await rabbitMQ.publish('auth-events', {
            type: 'email_sent',
            data: {
              email: to,
              subject,
              tokenData
            }
          });
        } catch (rmqError) {
          console.error('Failed to publish email event to RabbitMQ:', rmqError);
          // Don't fail the whole process if RabbitMQ fails
        }
      }
      
      return info;
    } catch (error) {
      console.error('Email sending failed:', error);
      
      // For testing: return success instead of throwing
      // Remove this in production
      console.log('DEVELOPMENT MODE: Simulating email success despite error');
      return { 
        messageId: 'mock-id',
        response: 'Mock success (email not actually sent)',
        mock: true,
        originalError: error.message
      };
      
      // Uncomment this for production:
      // throw error;
    }
  }
};