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
router.get("/me", auth, async (req, res) => {
  try {
    const user = req.user;

    res.status(200).json({
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
router.post("/create", async (req, res) => {
  const { email, password, firstName, lastName } = req.body;

  try {
    const existingUser = await User.findOne({ where: { email } });
    if (existingUser) {
      return res.status(400).json({ message: "User already exists" });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const newUser = await User.create({
      email,
      password: hashedPassword,
      firstName,
      lastName,
    });

    res.status(201).json({
      id: newUser.id, // Include the new UUID in the response
      email: newUser.email,
      firstName: newUser.firstName,
      lastName: newUser.lastName,
      account_created: newUser.account_created,
      account_updated: newUser.account_updated,
    });
  } catch (err) {
    res.status(500).json({ message: "Server error" });
  }
});

// Update current user's account information
// Update current user's account information
router.put("/me", auth, async (req, res) => {
  try {
    const user = req.user; // Get the authenticated user from the auth middleware

    const { firstName, lastName, password } = req.body;

    // Allowed fields for update
    const allowedFields = ["firstName", "lastName", "password"];

    // Validate that only allowed fields are being updated
    const updateFields = Object.keys(req.body);
    const isValidUpdate = updateFields.every((field) =>
      allowedFields.includes(field)
    );

    if (!isValidUpdate) {
      return res
        .status(400)
        .json({ message: "Invalid fields in request body" });
    }

    // Update only the allowed fields
    if (firstName) user.firstName = firstName;
    if (lastName) user.lastName = lastName;
    if (password) user.password = await bcrypt.hash(password, 10);

    user.account_updated = new Date(); // Update the account_updated field

    await user.save(); // Save the changes to the database

    res.status(200).json({
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

module.exports = router;
