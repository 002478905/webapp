const { Sequelize } = require("sequelize");
require("dotenv").config();
const StatsD = require("hot-shots");
const statsd = new StatsD({ host: "127.0.0.1", port: 8125 });
const sequelize = new Sequelize(
  process.env.DB_NAME,
  process.env.DB_USER,
  process.env.DB_PASSWORD,
  {
    host: process.env.DB_HOST,
    dialect: "postgres",
  }
);
sequelize.addHook("afterQuery", (options, query) => {
  const duration = query.executionTime; // This assumes executionTime is available
  statsd.timing("database.query.duration", duration);
});

module.exports = sequelize;
