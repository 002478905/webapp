const { Sequelize } = require("sequelize");
require("dotenv").config();
const StatsD = require("node-statsd");
const client = new StatsD({ host: "localhost", port: 8125 });

const sequelize = new Sequelize(
  process.env.DB_NAME,
  process.env.DB_USER,
  process.env.DB_PASSWORD,
  {
    host: process.env.DB_HOST,
    dialect: "postgres",
  },
  {
    host: process.env.DB_HOST,
    dialect: "postgres",
    logging: async (msg) => {
      const startTime = Date.now();

      console.log(msg); // Log SQL query

      const duration = Date.now() - startTime;

      // Send database query execution time metric in milliseconds
      client.timing("db.query_execution_time", duration);
    },
  }
);
module.exports = sequelize;
