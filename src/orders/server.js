// Telemetry first, so Express and HTTP are instrumented.
require("./src/telemetry");
const app = require("./src/app");

const port = Number(process.env.PORT) || 8080;
app.listen(port, () => console.log(`orders-api listening on ${port}`));
