const express = require("express");
const { Client, Pool } = require("pg");

const dotenv = require("dotenv");

// Load environment variables from .env file
dotenv.config();

const app = express();
const PORT = 8080;

// Parse JSON request bodies (even though we don't expect them for GET)
app.use(express.json());

//setting up the postgres connection

// const client = new Client({
//   user: process.env.DB_USER,
//   host: process.env.DB_HOST,
//   database: process.env.DB_NAME,
//   password: process.env.DB_PASSWORD,
//   port: process.env.DB_PORT || 5432,
// });

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

app.listen(PORT, () => {
  console.log(`Server is running on http://localhost:${PORT}`);
});
