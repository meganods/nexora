const fs = require('fs');
const path = require('path');
const transporter = require('../config/mail');

const sendMail = async ({ to, subject, html }) => {
  try {
    const fromName = process.env.SMTP_FROM_NAME || 'Nexora Support';
    const fromEmail = process.env.SMTP_FROM_EMAIL || 'no-reply@nexora.com';

    const info = await transporter.sendMail({
      from: `"${fromName}" <${fromEmail}>`,
      to,
      subject,
      html,
    });

    console.log(`Email dispatched successfully to ${to}. Message ID: ${info.messageId}`);
    return info;
  } catch (error) {
    console.error(`Email dispatch failed to ${to}:`, error.message);
    throw error;
  }
};

const sendTemplateMail = async (to, subject, templateName, replacements = {}) => {
  try {
    const templatePath = path.join(__dirname, '..', 'templates', `${templateName}.html`);
    let htmlContent = fs.readFileSync(templatePath, 'utf8');

    // Replace all placeholders like {{VARIABLE}}
    Object.keys(replacements).forEach(key => {
      const regex = new RegExp(`{{${key}}}`, 'g');
      htmlContent = htmlContent.replace(regex, replacements[key]);
    });

    return await sendMail({ to, subject, html: htmlContent });
  } catch (error) {
    console.error(`Failed to send template email:`, error.message);
    throw error;
  }
};

module.exports = {
  sendMail,
  sendTemplateMail
};
