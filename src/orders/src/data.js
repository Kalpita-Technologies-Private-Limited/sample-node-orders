// In-memory sample data (no database needed).
const customers = new Map([
  [1, { id: 1, name: "Asha Rao", email: " Asha.Rao@example.com " }],
  [2, { id: 2, name: "Vikram Iyer", email: "vikram@example.com" }],
  [3, { id: 3, name: "Meera Nair" }], // signed up by phone: no email on file
]);

const orders = new Map([
  [1, { id: 1, customerId: 1, items: [{ sku: "CAB-100", qty: 2, price: 249.5 }], address: { city: "Hyderabad", country: "IN" } }],
  [2, { id: 2, customerId: 2, items: [{ sku: "KBD-200", qty: 1, price: 1899 }, { sku: "MSE-300", qty: 1, price: 799 }], address: { city: "Pune", country: "IN" } }],
  [3, { id: 3, customerId: 1, items: [{ sku: "HDM-400", qty: 3, price: 99 }], address: { city: "Chennai", country: "IN" } }],
  [4, { id: 4, customerId: 3, items: [{ sku: "CAB-100", qty: 1, price: 249.5 }] }], // store pickup: no delivery address
]);

module.exports = { customers, orders };
