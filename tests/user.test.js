const request = require("supertest");
const app = require("../index");

describe("User API", () => {
  it("should create a new user", async () => {
    const res = await request(app).post("/api/users/create").send({
      email: "test@example.com",
      password: "password123",
      firstName: "Test",
      lastName: "User",
    });

    expect(res.statusCode).toEqual(201);
    expect(res.body).toHaveProperty("email");
  });
});
