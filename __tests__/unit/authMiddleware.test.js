const auth = require("../../middleware/auth");
const User = require("../../models/User");
const bcrypt = require("bcryptjs");
const httpMocks = require("node-mocks-http");
const sequelize = require("../../config/database");

describe("Auth Middleware", () => {
  beforeAll(async () => {
    await sequelize.sync({ force: true });
  });

  afterAll(async () => {
    await sequelize.close();
  });

  it("should return 401 if no authorization header is provided", async () => {
    const req = httpMocks.createRequest();
    const res = httpMocks.createResponse();
    const next = jest.fn();

    await auth(req, res, next);

    expect(res.statusCode).toBe(401);
    expect(JSON.parse(res._getData())).toEqual({
      message: "Missing authorization header",
    });
  });

  it("should call next if credentials are valid", async () => {
    const password = "password123";
    const hashedPassword = await bcrypt.hash(password, 10);
    await User.create({
      firstName: "Jane",
      lastName: "Doe",
      email: "jane.doe@example.com",
      password: hashedPassword,
    });

    const req = httpMocks.createRequest({
      headers: {
        authorization: `Basic ${Buffer.from(
          "jane.doe@example.com:password123"
        ).toString("base64")}`,
      },
    });
    const res = httpMocks.createResponse();
    const next = jest.fn();

    await auth(req, res, next);

    expect(next).toHaveBeenCalled();
  });
});
