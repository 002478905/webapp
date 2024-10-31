import { createLogger, format, transports } from "winston";
import moment from "moment-timezone";

// Function to format timestamps in EST timezone
const estTimestampFormat = () => {
  return moment().tz("America/New_York").format("YYYY-MM-DD HH:mm:ss");
};

// Create the logger
const logger = createLogger({
  level: "info",
  format: format.combine(
    format.timestamp({
      format: estTimestampFormat, // Use the custom timestamp format
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
    // File transport to log messages to a file
    new transports.File({
      filename: "/home/csye6225/webapp/logs/csye6225application.log", // Corrected file path (use a string)
    }),

    // Console transport to log messages to the console
    new transports.Console(),
  ],
});

export default logger;
