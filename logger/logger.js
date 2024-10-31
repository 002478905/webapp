const { createLogger, format, transports } = require("winston");
const moment = require("moment-timezone");

// Function to format timestamps in EST timezone
const estTimestampFormat = () => {
  return moment().tz("America/New_York").format("YYYY-MM-DD HH:mm:ss");
};

// Create the logger
const logger = createLogger({
  level: "info",
  format: format.combine(
    format.timestamp({
      format: estTimestampFormat,
    }),
    format.printf((info) =>
      JSON.stringify({
        timestamp: info.timestamp,
        level: info.level,
        message: info.message,
      })
    )
  ),
  transports: [
    new transports.File({
      filename: "/home/csye6225/webapp/logs/csye6225application.log",
    }),
    new transports.Console(),
  ],
});

module.exports = logger;
