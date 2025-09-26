const request = require("supertest");
const app = require("../server");

describe("Backend API Tests", () => {
  it("should return status ok on /health", async () => {
    const res = await request(app).get("/health");
    expect(res.statusCode).toBe(200);
    expect(res.body).toEqual({ status: "ok" });
  });

  it("should return billing data on /billing", async () => {
    const res = await request(app).get("/billing");
    expect(res.statusCode).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
    expect(res.body[0]).toHaveProperty("customer");
    expect(res.body[0]).toHaveProperty("amount");
  });
});
