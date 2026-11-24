const { test, before, after } = require("node:test");
const assert = require("node:assert");
const app = require("../src/app");

let server;
let base;
before(async () => {
  server = app.listen(0);
  await new Promise((r) => server.once("listening", r));
  base = `http://127.0.0.1:${server.address().port}`;
});
after(() => server.close());

const get = async (path) => {
  const res = await fetch(base + path);
  return { status: res.status, body: await res.json() };
};

test("health reports ok and a version", async () => {
  const { status, body } = await get("/health");
  assert.strictEqual(status, 200);
  assert.strictEqual(body.status, "ok");
  assert.ok(body.version);
});

test("order total sums quantity times price", async () => {
  const { body } = await get("/api/orders/2/total");
  assert.deepStrictEqual(body, { orderId: 2, total: 2698 });
});

test("unknown order is 404", async () => {
  assert.strictEqual((await get("/api/orders/99")).status, 404);
});

test("profile normalises the contact email", async () => {
  const { body } = await get("/api/customers/1/profile");
  assert.strictEqual(body.contactEmail, "asha.rao@example.com");
});

test("shipping label for a delivery order", async () => {
  const { body } = await get("/api/orders/1/shipping-label");
  assert.strictEqual(body.label, "HYDERABAD, IN");
});
