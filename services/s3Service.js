// services/s3Service.js

const AWS = require("aws-sdk");
const s3 = new AWS.S3();
const logger = require("../logger/logger");

// Upload file to S3
async function uploadFileToS3(key, fileContent) {
  const bucketName = process.env.S3_BUCKET_NAME;
  const params = { Bucket: bucketName, Key: key, Body: fileContent };

  try {
    const data = await s3.upload(params).promise();

    logger.info(`File uploaded successfully to S3 with key ${key}`);

    return data; // Return S3 response including URL location of the uploaded file
  } catch (error) {
    logger.error(`Error uploading file to S3: ${error.message}`);

    throw new Error("Error uploading file to S3");
  }
}

// Delete file from S3
async function deleteFileFromS3(key) {
  const bucketName = process.env.S3_BUCKET_NAME;
  const params = { Bucket: bucketName, Key: key };

  try {
    await s3.deleteObject(params).promise();

    logger.info(`File deleted successfully from S3 with key ${key}`);
  } catch (error) {
    logger.error(`Error deleting file from S3: ${error.message}`);

    throw new Error("Error deleting file from S3");
  }
}

module.exports = { uploadFileToS3, deleteFileFromS3 };
