const fs = require("fs");
const path = require("path");
const net = require("net");
const gateway = require("express-gateway");

process.env.LOG_LEVEL = "debug";

const configPath = path.join(__dirname, "config", "gateway.config.yml");
const preferredPort = Number(process.env.GATEWAY_PORT || 8090);
const preferredAdminPort = Number(process.env.GATEWAY_ADMIN_PORT || 9878);

function isPortAvailable(port, host) {
  return new Promise((resolve) => {
    const server = net.createServer();
    server.once("error", () => resolve(false));
    server.once("listening", () => {
      server.close(() => resolve(true));
    });
    server.listen(port, host);
  });
}

async function getAvailablePort(startPort, host) {
  let port = startPort;
  while (port < startPort + 50) {
    if (await isPortAvailable(port, host)) {
      return port;
    }
    port += 1;
  }
  throw new Error(`No available port found starting from ${startPort}`);
}

async function updateGatewayConfig(httpPort, adminPort) {
  const original = fs.readFileSync(configPath, "utf8");
  const updated = original
    .replace(/http:\s*\n\s*port:\s*\d+/m, `http:\n  port: ${httpPort}`)
    .replace(/admin:\s*\n\s*port:\s*\d+/m, `admin:\n  port: ${adminPort}`);

  if (updated !== original) {
    fs.writeFileSync(configPath, updated);
  }
}

(async () => {
  const httpPort = await getAvailablePort(preferredPort, "::");
  const adminPort = await getAvailablePort(preferredAdminPort, "::1");
  await updateGatewayConfig(httpPort, adminPort);

  console.log(`Using gateway ports: http=${httpPort}, admin=${adminPort}`);

  gateway().load(path.join(__dirname, "config")).run();
})();
