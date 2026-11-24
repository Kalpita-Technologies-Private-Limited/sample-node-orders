const express = require("express");
const { customers, orders } = require("./data");
const { version, trackException } = require("./telemetry");

const app = express();

app.get("/health", (_req, res) => res.json({ status: "ok", version }));

app.get("/api/orders/:id", function getOrder(req, res) {
  const order = orders.get(Number(req.params.id));
  if (!order) return res.status(404).json({ error: "Order not found" });
  res.json(order);
});

app.get("/api/orders/:id/total", function orderTotal(req, res) {
  const order = orders.get(Number(req.params.id));
  if (!order) return res.status(404).json({ error: "Order not found" });
  const total = order.items.reduce((sum, i) => sum + i.qty * i.price, 0);
  res.json({ orderId: order.id, total: Math.round(total * 100) / 100 });
});

// SEEDED BUG (for the Self Healing AI Assistant): customers without an email (customer 3) throw a TypeError.
app.get("/api/customers/:id/profile", function customerProfile(req, res) {
  const customer = customers.get(Number(req.params.id));
  if (!customer) return res.status(404).json({ error: "Customer not found" });
  res.json({ id: customer.id, name: customer.name, contactEmail: customer.email.trim().toLowerCase() });
});

// SEEDED BUG (for the Self Healing AI Assistant): store-pickup orders have no address (order 4) and throw a TypeError.
app.get("/api/orders/:id/shipping-label", function shippingLabel(req, res) {
  const order = orders.get(Number(req.params.id));
  if (!order) return res.status(404).json({ error: "Order not found" });
  res.json({ orderId: order.id, label: `${order.address.city.toUpperCase()}, ${order.address.country}` });
});

// Unhandled errors: report to App Insights, answer 500 without details.
app.use((err, req, res, _next) => {
  trackException(err, req);
  res.status(500).json({ error: "Internal error" });
});

module.exports = app;
