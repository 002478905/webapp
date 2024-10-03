const User = require("../../models/User");
const sequelize = require("../../config/database");

describe("User Model", () => {
  beforeAll(async () => {
    await sequelize.sync({ force: true }); // Sync the database before tests
  });

  afterAll(async () => {
    await sequelize.close(); // Close the database connection after all tests
  });

  it("should create a user with correct properties", async () => {
    const user = await User.create({
      email: "jane.doe@example.com",
      password: "password123",
      firstName: "Jane",
      lastName: "Doe",
    });

    expect(user).toHaveProperty("id");
    expect(user.email).toBe("jane.doe@example.com");
    expect(user.firstName).toBe("Jane");
    expect(user.lastName).toBe("Doe");
  });
});
