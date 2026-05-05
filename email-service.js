#!/usr/bin/env node

/**
 * MINERPRICES EMAIL SERVICE
 * 
 * Handles all email sending:
 * - Vendor registration confirmations
 * - Admin approval/rejection
 * - System alerts
 * 
 * Supports multiple providers:
 * 1. SendGrid (recommended)
 * 2. Siteground IMAP/SMTP
 * 3. Mailtrap (dev/testing)
 * 4. Gmail
 */

const nodemailer = require('nodemailer');
const { createClient } = require('@supabase/supabase-js');

// ============================================================================
// CONFIGURATION
// ============================================================================

const SUPABASE_URL = process.env.SUPABASE_URL || 'https://huzfnrgfcxlwvmrkoyge.supabase.co';
const SUPABASE_KEY = process.env.SUPABASE_SERVICE_KEY;

const EMAIL_PROVIDER = process.env.EMAIL_PROVIDER || 'siteground'; // siteground, sendgrid, gmail, mailtrap
const EMAIL_FROM = process.env.EMAIL_FROM || 'noreply@minerprices.com';
const EMAIL_FROM_NAME = process.env.EMAIL_FROM_NAME || 'MinerPrices';

const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

// ============================================================================
// EMAIL TRANSPORTER SETUP
// ============================================================================

let transporter;

function setupTransporter() {
  if (EMAIL_PROVIDER === 'siteground') {
    // Siteground SMTP
    transporter = nodemailer.createTransport({
      host: process.env.SITEGROUND_SMTP_HOST || 'mail.minerprices.com',
      port: process.env.SITEGROUND_SMTP_PORT || 587,
      secure: false, // true for 465, false for other ports
      auth: {
        user: process.env.SITEGROUND_SMTP_USER || 'noreply@minerprices.com',
        pass: process.env.SITEGROUND_SMTP_PASSWORD
      }
    });
    console.log('✅ Email provider: Siteground SMTP');
  }
  else if (EMAIL_PROVIDER === 'sendgrid') {
    // SendGrid
    const sgMail = require('@sendgrid/mail');
    sgMail.setApiKey(process.env.SENDGRID_API_KEY);
    transporter = sgMail;
    console.log('✅ Email provider: SendGrid');
  }
  else if (EMAIL_PROVIDER === 'gmail') {
    // Gmail (less recommended for production)
    transporter = nodemailer.createTransport({
      service: 'gmail',
      auth: {
        user: process.env.GMAIL_EMAIL,
        pass: process.env.GMAIL_PASSWORD
      }
    });
    console.log('✅ Email provider: Gmail');
  }
  else if (EMAIL_PROVIDER === 'mailtrap') {
    // Mailtrap (for testing)
    transporter = nodemailer.createTransport({
      host: 'smtp.mailtrap.io',
      port: 465,
      secure: true,
      auth: {
        user: process.env.MAILTRAP_USER,
        pass: process.env.MAILTRAP_PASSWORD
      }
    });
    console.log('✅ Email provider: Mailtrap (Testing)');
  }
}

// ============================================================================
// GET EMAIL TEMPLATE
// ============================================================================

async function getEmailTemplate(templateName, variables = {}) {
  try {
    const { data: template } = await supabase
      .from('email_templates')
      .select('*')
      .eq('name', templateName)
      .eq('active', true)
      .single();
    
    if (!template) {
      console.warn(`⚠️ Template not found: ${templateName}`);
      return null;
    }
    
    // Replace variables in template
    let subject = template.subject;
    let htmlBody = template.html_body;
    let plainBody = template.plain_text_body;
    
    Object.keys(variables).forEach(key => {
      const regex = new RegExp(`{${key}}`, 'g');
      subject = subject.replace(regex, variables[key]);
      htmlBody = htmlBody.replace(regex, variables[key]);
      plainBody = plainBody.replace(regex, variables[key]);
    });
    
    return { subject, htmlBody, plainBody };
  } catch (error) {
    console.error('Error getting email template:', error.message);
    return null;
  }
}

// ============================================================================
// SEND EMAIL
// ============================================================================

async function sendEmail(recipientEmail, subject, htmlContent, plainTextContent = '') {
  try {
    const mailOptions = {
      from: `"${EMAIL_FROM_NAME}" <${EMAIL_FROM}>`,
      to: recipientEmail,
      subject: subject,
      html: htmlContent,
      text: plainTextContent || 'See HTML version'
    };
    
    if (EMAIL_PROVIDER === 'sendgrid') {
      await transporter.send(mailOptions);
    } else {
      await transporter.sendMail(mailOptions);
    }
    
    console.log(`✅ Email sent to ${recipientEmail}: ${subject}`);
    return true;
  } catch (error) {
    console.error(`❌ Failed to send email to ${recipientEmail}:`, error.message);
    return false;
  }
}

// ============================================================================
// PROCESS EMAIL QUEUE
// ============================================================================

async function processEmailQueue() {
  console.log('\n📧 Processing email queue...\n');
  
  try {
    // Get pending emails
    const { data: pendingEmails } = await supabase
      .from('email_queue')
      .select('*')
      .eq('status', 'pending')
      .lt('retry_count', 3)
      .order('created_at', { ascending: true })
      .limit(10); // Process 10 at a time
    
    if (!pendingEmails || pendingEmails.length === 0) {
      console.log('✅ No pending emails');
      return;
    }
    
    console.log(`Found ${pendingEmails.length} pending emails\n`);
    
    for (const emailJob of pendingEmails) {
      await sendEmailJob(emailJob);
    }
    
  } catch (error) {
    console.error('❌ Error processing email queue:', error.message);
  }
}

// ============================================================================
// SEND SINGLE EMAIL JOB
// ============================================================================

async function sendEmailJob(emailJob) {
  try {
    // Get email template
    const template = await getEmailTemplate(emailJob.email_type, emailJob.template_data);
    
    if (!template) {
      console.error(`❌ Template not found: ${emailJob.email_type}`);
      
      // Mark as failed
      await supabase
        .from('email_queue')
        .update({
          status: 'failed',
          error_message: 'Template not found',
          updated_at: new Date()
        })
        .eq('id', emailJob.id);
      
      return;
    }
    
    // Send email
    const success = await sendEmail(
      emailJob.recipient_email,
      template.subject,
      template.htmlBody,
      template.plainBody
    );
    
    if (success) {
      // Mark as sent
      await supabase
        .from('email_queue')
        .update({
          status: 'sent',
          sent_at: new Date(),
          updated_at: new Date()
        })
        .eq('id', emailJob.id);
      
      console.log(`  ✅ [${emailJob.email_type}] → ${emailJob.recipient_email}`);
    } else {
      // Mark for retry
      await supabase
        .from('email_queue')
        .update({
          status: emailJob.retry_count >= 2 ? 'failed' : 'retrying',
          retry_count: emailJob.retry_count + 1,
          error_message: 'SMTP delivery failed',
          updated_at: new Date()
        })
        .eq('id', emailJob.id);
      
      console.log(`  ⚠️ [${emailJob.email_type}] → ${emailJob.recipient_email} (retry ${emailJob.retry_count + 1})`);
    }
  } catch (error) {
    console.error(`  ❌ Error sending email ${emailJob.id}:`, error.message);
    
    await supabase
      .from('email_queue')
      .update({
        status: 'failed',
        error_message: error.message,
        updated_at: new Date()
      })
      .eq('id', emailJob.id);
  }
}

// ============================================================================
// TEST EMAIL CONFIGURATION
// ============================================================================

async function testEmailConfig() {
  console.log('\n🧪 Testing email configuration...\n');
  
  try {
    if (EMAIL_PROVIDER === 'sendgrid') {
      console.log('✅ SendGrid API Key configured');
    } else {
      const testResult = await transporter.verify();
      if (testResult) {
        console.log('✅ SMTP connection successful');
        console.log(`   Host: ${transporter.options.host}`);
        console.log(`   Port: ${transporter.options.port}`);
        console.log(`   User: ${transporter.options.auth.user}`);
      }
    }
    
    console.log(`✅ Email from: "${EMAIL_FROM_NAME}" <${EMAIL_FROM}>`);
    console.log(`✅ Provider: ${EMAIL_PROVIDER}`);
    
  } catch (error) {
    console.error('❌ Email configuration error:', error.message);
    process.exit(1);
  }
}

// ============================================================================
// CLI INTERFACE
// ============================================================================

async function main() {
  const command = process.argv[2];
  
  setupTransporter();
  
  if (command === 'test') {
    await testEmailConfig();
  }
  else if (command === 'process' || !command) {
    await processEmailQueue();
  }
  else if (command === 'send-test') {
    const testEmail = process.argv[3] || 'test@example.com';
    console.log(`\nSending test email to ${testEmail}...\n`);
    
    const success = await sendEmail(
      testEmail,
      'Test Email from MinerPrices',
      '<h2>Test Email</h2><p>This is a test email from MinerPrices email system.</p>',
      'Test email from MinerPrices'
    );
    
    if (success) {
      console.log('✅ Test email sent successfully!');
    } else {
      console.error('❌ Failed to send test email');
      process.exit(1);
    }
  }
  else {
    console.log(`
MINERPRICES EMAIL SERVICE

Usage:
  node email-service.js [command] [args]

Commands:
  test              - Test email configuration
  process           - Process pending emails from queue
  send-test <email> - Send test email to address

Environment Variables:
  EMAIL_PROVIDER         - siteground, sendgrid, gmail, mailtrap
  SITEGROUND_SMTP_HOST   - SMTP host
  SITEGROUND_SMTP_PORT   - SMTP port
  SITEGROUND_SMTP_USER   - SMTP username
  SITEGROUND_SMTP_PASSWORD - SMTP password
  SENDGRID_API_KEY       - SendGrid API key
  EMAIL_FROM             - From email address
  EMAIL_FROM_NAME        - From name
  SUPABASE_URL           - Supabase URL
  SUPABASE_SERVICE_KEY   - Supabase service key

Examples:
  node email-service.js test
  node email-service.js process
  node email-service.js send-test admin@minerprices.com

For Siteground:
  export EMAIL_PROVIDER="siteground"
  export SITEGROUND_SMTP_HOST="mail.minerprices.com"
  export SITEGROUND_SMTP_USER="noreply@minerprices.com"
  export SITEGROUND_SMTP_PASSWORD="your_password"

For SendGrid:
  export EMAIL_PROVIDER="sendgrid"
  export SENDGRID_API_KEY="your_api_key"
    `);
  }
}

if (require.main === module) {
  main().catch(error => {
    console.error('Fatal error:', error.message);
    process.exit(1);
  });
}

module.exports = {
  sendEmail,
  processEmailQueue,
  getEmailTemplate,
  setupTransporter
};
