# sample-node-orders

Sample **Node.js (Express)** application healed by the Self Healing AI Assistant (app id `orders-gh`), hosted on GitHub.
It is a small orders API with two planted bugs, normal passing tests, and the assistant's telemetry contract.

| Endpoint | Behaviour |
|---|---|
| `GET /health` | `{ status, version }` (version = deployed commit from `.healer-version`) |
| `GET /api/orders/{id}`, `/api/orders/{id}/total` | work |
| `GET /api/customers/3/profile` | **planted bug**: customer without an email -> `TypeError` |
| `GET /api/orders/4/shipping-label` | **planted bug**: store-pickup order without an address -> `TypeError` |

- Code: `src/orders` (`npm start`, `npm test` with `node:test`).
- Telemetry: `@azure/monitor-opentelemetry` with the app's managed identity; unhandled errors are sent as exceptions with
  `CommitSha` and `Slot` (`src/telemetry.js`).
- Workflows: `.github/workflows/orders-gh-pr.yml` (PR build) and `orders-gh-cd.yml` (deploy to staging, swap to
  production after the `orders-gh-prod` environment approval, bake, rollback). They sign in to Azure with OIDC; the
  repository holds no secrets.

The planted bugs are intentional: the assistant's fixes stay as open pull requests so the bugs can be triggered again.
