const winston = require("winston");
const WinstonCloudWatch = require("winston-cloudwatch");

const logger = new winston.createLogger({
  format: winston.format.json(),
  transports: [
    new winston.transports.Console({
      timestamp: true,
      colorize: true,
      level: "info",
    }),
  ],
});

const cloudwatchConfig = {
  logGroupName: process.env.CLOUDWATCH_GROUP_NAME,
  logStreamName: process.env.CLOUDWATCH_STREAM_NAME,
  awsAccessKeyId: process.env.AWS_ACCESS_KEY_ID,
  awsSecretKey: process.env.AWS_SECRET_ACCESS_KEY,
  awsRegion: process.env.CLOUDWATCH_REGION,
  messageFormatter: ({ level, message, additionalInfo }) => {
    console.log("----logs printed", level, message, additionalInfo);
    return `[${level}] : ${JSON.stringify(
      message
    )} \nAdditional Info: ${JSON.stringify(additionalInfo)}}`;
  },
};
const loggerMiddleWare = (req, res, next) => {
  const now = Date.now();
  const { method, originalUrl } = req;
  const userAgent = req.get("user-agent") || "";
  const androidBuildNo = req.get("build-number") || "";
  let body = null;
  if (req.body.password) {
    body = { ...req.body, password: "*********" };
  } else {
    body = req.body;
  }
  const oldJson = res.json;
  res.json = (responseBody) => {
    const size = Buffer.byteLength(JSON.stringify(responseBody)) / 1024;
    let finalResponse = responseBody;
    if (size > 256) {
      finalResponse =
        "This message is too large to be delivered to the cloudWatchLogs.";
    }
    const resp = {
      url: `${method} ${originalUrl} ${
        req.clientIp
      } ${userAgent} ${androidBuildNo} ${Date.now() - now} ms`,
      request: {
        body: body,
        token: req.headers.authorization,
      },
      response: {
        status: res.statusCode,
        resBody: finalResponse,
      },
    };
    logger.info(resp);
    return oldJson.call(res, responseBody);
  };
  next();
};
logger.add(new WinstonCloudWatch(cloudwatchConfig));

module.exports = { loggerMiddleWare, logger };
