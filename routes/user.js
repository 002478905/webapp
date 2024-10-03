const express = require("express");
const bcrypt = require("bcryptjs");
const User = require("../models/User");
const router = express.Router();
const auth = require("../middleware/auth");
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
    const user = req.user;

    res.status(200).json({
      id: user.id,
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName,
      account_created: user.account_created,
      account_updated: user.account_updated,
    });
  } catch (err) {
    res.status(500).json({ message: "Server error" });
  }
});

// Create a new user
router.post("/", async (req, res) => {
  const { email, password, first_name, last_name } = req.body;

  try {
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
  } catch (err) {
    res.status(500).json({ message: "Server error" });
  }
});
// Catch-all for unsupported methods on /v1/user/self
router.all("/self", (req, res) => {
  res.set("Allow", "GET PUT"); // Specify which methods are allowed
  res.status(405).json({ message: "Method Not Allowed" });
});

module.exports = router;
