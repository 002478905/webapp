// services/s3Service.js

const AWS = require("aws-sdk");
const s3 = new AWS.S3();
const StatsD = require("node-statsd");
const client = new StatsD({ host: "localhost", port: 8125 });
const logger = require("../logger/logger"); // Import the logger
async function uploadFileToS3(bucketName, key, fileContent) {
  const startTime = Date.now(); // Start timer

  try {
    const params = { Bucket: bucketName, Key: key, Body: fileContent };
    logger.info(`Uploading file to S3 bucket ${bucketName} with key ${key}`); // Log file upload
    await s3.upload(params).promise(); // Upload file to S3

    // Send S3 service call time metric in milliseconds to CloudWatch via StatsD
    client.timing("s3.service_call_time.upload", duration);
    const duration = Date.now() - startTime; // Calculate duration

    // Send S3 service call time metric in milliseconds to CloudWatch via StatsD
    client.timing("s3.service_call_time.upload", duration);

    logger.info(`File uploaded successfully in ${duration}ms`); // Log success
  } catch (error) {
    console.error("Error uploading file:", error);
  }
}

module.exports = { uploadFileToS3 };
