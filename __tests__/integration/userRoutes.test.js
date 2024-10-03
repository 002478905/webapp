const request = require("supertest");
const sequelize = require("../../config/database");
const server = require("../../index");

describe("User Routes", () => {
  beforeAll(async () => {
    await sequelize.sync({ force: true }); // Recreate the database for testing
  });

  afterAll(async () => {
    await sequelize.close(); // Close database connection
    // server.close(); // Close the server
  });

  describe("POST /v1/user", () => {
    it("should create a new user", async () => {
      const res = await request(server).post("/v1/user").send({
        first_name: "Jane",
        last_name: "Doe",
        password: "password123",
        email: "jane.doe@example.com",
      });

      expect(res.statusCode).toBe(201);
      expect(res.body).toHaveProperty("id");
      expect(res.body.first_name).toBe("Jane");
      expect(res.body.last_name).toBe("Doe");
    });

    it("should not create a user with an existing email", async () => {
      const res = await request(server).post("/v1/user").send({
        first_name: "Jane",
        last_name: "Doe",
        password: "password123",
        email: "jane.doe@example.com",
      });

      expect(res.statusCode).toBe(400);
      expect(res.body).toHaveProperty("message", "User already exists");
    });
  });

  describe("GET /v1/user/self", () => {
    it("should return user information for authenticated user", async () => {
      const res = await request(server)
        .get("/v1/user/self")
        .auth("jane.doe@example.com", "password123");

      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty("email", "jane.doe@example.com");
      expect(res.body).toHaveProperty("firstName", "Jane"); // Change from first_name to firstName
      expect(res.body).toHaveProperty("lastName", "Doe"); // Change from last_name to lastName
    });

    it("should return 401 for unauthenticated requests", async () => {
      const res = await request(server).get("/v1/user/self");

      expect(res.statusCode).toBe(401);
      expect(res.body).toHaveProperty(
        "message",
        "Missing authorization header"
      );
    });
  });
});
