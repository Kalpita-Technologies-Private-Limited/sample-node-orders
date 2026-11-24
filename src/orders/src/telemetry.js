// Telemetry contract of the Self Healing AI Assistant (docs/conventions.md in the SelfHealingBot repo):
// - exceptions go to App Insights with custom properties CommitSha and Slot,
// - App Insights local auth is off: the app signs in with its managed identity (AZURE_CLIENT_ID),
// - /health reports the deployed commit (.healer-version, written by the pipeline).
const fs = require("node:fs");
const path = require("node:path");

const version = (() => {
  try {
    return fs.readFileSync(path.join(__dirname, "..", ".healer-version"), "utf8").trim();
  } catch {
    return "local";
  }
})();
const slot = process.env.Healer__Slot || "local";

let logger = null;
if (process.env.APPLICATIONINSIGHTS_CONNECTION_STRING) {
  const { useAzureMonitor } = require("@azure/monitor-opentelemetry");
  const { ManagedIdentityCredential } = require("@azure/identity");
  useAzureMonitor({
    azureMonitorExporterOptions: {
      connectionString: process.env.APPLICATIONINSIGHTS_CONNECTION_STRING,
      credential: new ManagedIdentityCredential({ clientId: process.env.AZURE_CLIENT_ID }),
    },
  });
  logger = require("@opentelemetry/api-logs").logs.getLogger("orders-api");
}

/** Sends an exception to App Insights (AppExceptions) with CommitSha and Slot; also prints it. */
function trackException(error, request) {
  console.error(error);
  if (!logger) return;
  logger.emit({
    severityNumber: 17, // ERROR
    severityText: "ERROR",
    body: error.message,
    attributes: {
      "exception.type": error.name,
      "exception.message": error.message,
      "exception.stacktrace": error.stack,
      CommitSha: version,
      Slot: slot,
      "http.route": request?.route?.path ?? request?.path ?? "",
    },
  });
}

module.exports = { version, slot, trackException };
