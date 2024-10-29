const AWS = require("aws-sdk");
const StatsD = require("hot-shots");
const statsd = new StatsD({ host: "127.0.0.1", port: 8125 });

const s3 = new AWS.S3();

async function uploadImage(params) {
  const startTime = Date.now();
  try {
    const result = await s3.upload(params).promise();
    return result;
  } finally {
    const duration = Date.now() - startTime;
    statsd.timing("s3.upload.duration", duration); // Logs duration of upload
  }
}

async function deleteImage(params) {
  const startTime = Date.now();
  try {
    const result = await s3.deleteObject(params).promise();
    return result;
  } finally {
    const duration = Date.now() - startTime;
    statsd.timing("s3.delete.duration", duration); // Logs duration of deletion
  }
}

module.exports = { uploadImage, deleteImage };
