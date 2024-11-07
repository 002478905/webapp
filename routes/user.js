const express = require("express");
const multer = require("multer"); // For handling multipart form data
const bcrypt = require("bcryptjs");
const User = require("../models/User");
const router = express.Router();
const auth = require("../middleware/auth");
const { uploadFileToS3 } = require("../services/s3Service");
const StatsD = require("node-statsd");
const client = new StatsD({ host: "localhost", port: 8125 });
const logger = require("../logger/logger");
const ImageMetadata = require("../models/ImageMetadata"); // Import ImageMetadata model

const startTime = Date.now(); // Start timer for response time

// GET route for getting user information
router.get("/", async (req, res) => {
  try {
    // Logic for fetching users or specific user info
    res.status(200).json({ message: "GET request successful" });
  } catch (err) {
    res.status(500).json({ message: "Server error" });
  }
});
// Get current user's account information
router.get("/self", auth, async (req, res) => {
  try {
    // Log the API call
    logger.info("GET /self API called");
    // Increment API call count metric
    client.increment("api.calls.self");
    const user = req.user;

    res.status(200).json({
      id: user.id,
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName,
      account_created: user.account_created,
      account_updated: user.account_updated,
    });
    const duration = Date.now() - startTime;

    // Send response time metric in milliseconds
    client.timing("api.response_time.self", duration);
    // Log the response time
    logger.info(`GET /self API responded in ${duration}ms`);
  } catch (err) {
    res.status(500).json({ message: "Server error" });
  }
});

// Create a new user
router.post("/", async (req, res) => {
  const { email, password, first_name, last_name } = req.body;

  try {
    // Log the API call
    logger.info("POST / API called");
    // Increment API call count metric
    client.increment("api.calls.self");
    // Check if a user with the given email already exists
    const existingUser = await User.findOne({ where: { email } });
    if (existingUser) {
      return res.status(400).json({ message: "User already exists" });
    }

    // Create a new user with hashed password
    const hashedPassword = await bcrypt.hash(password, 10);

    const newUser = await User.create({
      email,
      password: hashedPassword,
      firstName: first_name,
      lastName: last_name,
    });

    // Return the response with the user details
    res.status(201).json({
      id: newUser.id,
      first_name: newUser.firstName,
      last_name: newUser.lastName,
      email: newUser.email,
      account_created: newUser.account_created,
      account_updated: newUser.account_updated,
    });
    const duration = Date.now() - startTime;

    // Send response time metric in milliseconds
    client.timing("api.response_time.self", duration);

    // Log the response time
    logger.info(`POST / API responded in ${duration}ms`);
  } catch (err) {
    // If Sequelize throws a validation error, return a 400 status code
    if (err.name === "SequelizeValidationError") {
      return res.status(400).json({ message: "Invalid email format" });
    }

    // For other errors, pass it to the global error handler
    res.status(500).json({ message: "Server error" });
  }
});

// Update current user's account information
// Update current user's account information
router.put("/self", auth, async (req, res) => {
  try {
    const user = req.user; // Get the authenticated user from the auth middleware
    // Log the API call
    logger.info("PUT /self API called");

    // Increment API call count metric
    client.increment("api.calls.self");
    const { firstName, lastName, password, email } = req.body;

    // Allowed fields for update
    const allowedFields = ["firstName", "lastName", "password", "email"];

    // Validate that only allowed fields are being updated
    const updateFields = Object.keys(req.body);
    const isInValidUpdate = updateFields.every(
      (field) => !allowedFields.includes(field)
    );

    if (user.email !== email || isInValidUpdate) {
      return res
        .status(400)
        .json({ message: "Invalid fields in request body" });
    }

    // Update only the allowed fields
    if (firstName) user.firstName = firstName;
    if (lastName) user.lastName = lastName;
    if (password) user.password = await bcrypt.hash(password, 10);

    user.account_updated = new Date(); // Update the account_updated field

    // await user.save(); // Save the changes to the database

    res.status(204).json({
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName,
      account_created: user.account_created,
      account_updated: user.account_updated,
    });
    const duration = Date.now() - startTime;

    // Send response time metric in milliseconds
    client.timing("api.response_time.self", duration);

    // Log the response time
    logger.info(`PUT /self API responded in ${duration}ms`);
  } catch (err) {
    res.status(500).json({ message: "Server error" });
  }
});
// Catch-all for unsupported methods on /v1/user/self
router.all("/self", (req, res) => {
  res.set("Allow", "GET PUT"); // Specify which methods are allowed
  res.status(405).json({ message: "Method Not Allowed" });
});
router.post("/upload", async (req, res) => {
  const bucketName = process.env.S3_BUCKET_NAME;
  const { key, fileContent } = req.body; // Assume these are passed in the request body

  try {
    await uploadFileToS3(key, fileContent);
    res.status(200).json({ message: "File uploaded successfully" });
  } catch (error) {
    res.status(500).json({ message: "Error uploading file" });
  }
});

// Multer configuration for handling file uploads
// Multer configuration for handling file uploads
const upload = multer({
  limits: {
    fileSize: 5 * 1024 * 1024, // Limit file size to 5MB
  },
  fileFilter(req, file, cb) {
    // Check for valid MIME types
    const allowedMimeTypes = ["image/jpeg", "image/png", "image/jpg"];

    if (!allowedMimeTypes.includes(file.mimetype)) {
      return cb(new Error("Please upload an image file (jpg, jpeg, png)"));
    }

    // If valid, accept the file
    cb(null, true);
  },
});

// POST /v1/user/self/pic - Upload or update profile picture
router.post(
  "/self/pic",
  auth,
  upload.single("profilePic"),
  async (req, res) => {
    try {
      const user = req.user;
      const fileContent = req.file.buffer;
      const fileName = `${user.id}-${Date.now()}.${
        req.file.mimetype.split("/")[1]
      }`;
      const bucketName = process.env.S3_BUCKET_NAME;
      // Upload image to S3
      const s3Response = await uploadFileToS3(fileName, fileContent);

      // Store metadata in the database
      const imageMetadata = await ImageMetadata.create({
        user_id: user.id,
        file_name: req.file.originalname,
        url: s3Response.Location,
        upload_date: new Date(),
      });

      // Log success
      logger.info(`Profile picture uploaded for user ${user.id}`);

      // Respond with metadata
      res.status(201).json(imageMetadata);
    } catch (error) {
      logger.error(`Error uploading profile picture: ${error.message}`);
      res.status(400).json({ message: "Error uploading profile picture" });
    }
  }
);
// GET /v1/user/self/pic - Get profile picture metadata
router.get("/self/pic", auth, async (req, res) => {
  try {
    const user = req.user;

    // Retrieve metadata from the database
    const metadata = await ImageMetadata.findOne({
      where: { user_id: user.id },
    });

    if (!metadata) {
      return res.status(404).json({ message: "Profile picture not found" });
    }

    // Log success
    logger.info(`Profile picture retrieved for user ${user.id}`);

    // Respond with metadata
    res.status(200).json(metadata);
  } catch (error) {
    logger.error(`Error retrieving profile picture: ${error.message}`);
    res.status(500).json({ message: "Error retrieving profile picture" });
  }
});
// DELETE /v1/user/self/pic - Delete profile picture
router.delete("/self/pic", auth, async (req, res) => {
  try {
    const user = req.user;

    // Get metadata from the database
    const metadata = await ImageMetadata.findOne({
      where: { user_id: user.id },
    });

    if (!metadata) {
      return res.status(404).json({ message: "Profile picture not found" });
    }

    // Delete image from S3
    await deleteFileFromS3("your-s3-bucket-name", metadata.file_name);

    // Delete metadata from the database
    await ImageMetadata.destroy({ where: { user_id: user.id } });

    // Log success
    logger.info(`Profile picture deleted for user ${user.id}`);

    res.status(204).send(); // No content response on successful deletion
  } catch (error) {
    logger.error(`Error deleting profile picture: ${error.message}`);
    res.status(500).json({ message: "Error deleting profile picture" });
  }
});
// Catch-all route for unsupported methods on /v1/user/self/pic
router.all("/self/pic", (req, res) => {
  res.set("Allow", "GET, POST, DELETE"); // Specify which methods are allowed
  res.status(405).json({ message: "Method Not Allowed" });
});

module.exports = router;
