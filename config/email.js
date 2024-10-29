const sgMail = require("@sendgrid/mail");
require("dotenv").config();

sgMail.setApiKey(process.env.SENDGRID_API_KEY);

const sendEmail = async (to, subject, text, html) => {
  try {
    await sgMail.send({ to, from: "@pankhurigupta.me", subject, text, html });
    console.log("Email sent");
  } catch (error) {
    console.error("Error sending email:", error);
  }
};

module.exports = { sendEmail };
