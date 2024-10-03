const express = require("express");
const { Client, Pool } = require("pg");
const sequelize = require("./config/database");
const User = require("./models/User");
const userRoutes = require("./routes/user"); // Import the user routes

const dotenv = require("dotenv");

// Load environment variables from .env file
dotenv.config();

sequelize
  .sync({ alter: true })
  .then(() => {
    console.log("Database synced successfully");
  })
  .catch((err) => {
    console.error("Error syncing database:", err);
  });

const app = express();
const PORT = 8080;

// Parse JSON request bodies (even though we don't expect them for GET)
app.use(express.json());
app.use("/v1/user", userRoutes);

//setting up the postgres connection

const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: process.env.DB_PASSWORD,
  port: process.env.DB_PORT || 5432,
});

// Health check endpoint
app.all("/healthz", async (req, res) => {
  if (req.method !== "GET") {
    res.set("Cache-Control", "no-cache, no-store, must-revalidate");
    res.set("Pragma", "no-cache");
    res.set("X-Content-Type-Options", "nosniff");
    return res.status(405).send(); // Method Not Allowed for non-GET methods
  }

  if (req.headers["content-length"] && req.headers["content-length"] !== "0") {
    return res.status(400).send(); // Return 400 Bad Request if there's a payload
  }
  // Check for any query parameters in the request
  if (Object.keys(req.query).length > 0) {
    return res
      .status(400)
      .send({ message: "Query parameters are not allowed" }); // Return 400 Bad Request if query parameters are present
  }
  try {
    // Explicitly create a new client and connect to the database
    console.log("Attempting to connect to the database...");
    const client = await pool.connect(); // Await the connection attempt
    await client.query("SELECT NOW()"); // Run a query to check if the connection works
    client.release(); // Release the connection back to the pool

    res.set("Cache-Control", "no-cache, no-store, must-revalidate");
    res.set("Pragma", "no-cache");
    res.set("X-Content-Type-Options", "nosniff");
    return res.status(200).send(); // OK if connected to the DB
  } catch (error) {
    console.error("Error connecting to the database:", error.message); // Log error
    res.set("Cache-Control", "no-cache, no-store, must-revalidate");
    res.set("Pragma", "no-cache");
    res.set("X-Content-Type-Options", "nosniff");
    return res.status(503).send(); // Service Unavailable if DB connection fails
  }
});
// Register user routes with the /api/users path
app.use("/v1/user", userRoutes);

app.listen(PORT, () => {
  console.log(`Server is running on http://localhost:${PORT}`);
});

module.exports = app;
