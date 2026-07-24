"use strict";

/*
 * PC Connector – Web backend (Backend-for-Frontend)
 * -------------------------------------------------
 * Responsibilities that a browser cannot do on its own:
 *   1. Serve the compiled Angular SPA (static files).
 *   2. Proxy every /proxy/** request to the selected PC agent. This bypasses
 *      CORS (the agent sends no CORS headers) and lets <img>/<a> tags carry the
 *      bearer token via query params (__base / __token) that we translate into
 *      an Authorization header.
 *   3. Send Wake-on-LAN magic packets from this always-on server.
 *   4. Discover PC agents on the LAN via UDP broadcast (same protocol as the
 *      mobile app: magic string "PCCONNECTOR_DISCOVER" on UDP port 8421).
 *
 * WOL + discovery use UDP broadcast, so the container must run with host
 * networking on Proxmox (see docker-compose.yml).
 */

const express = require("express");
const httpProxy = require("http-proxy");
const dgram = require("dgram");
const path = require("path");

const PORT = parseInt(process.env.PORT || "8080", 10);
const DISCOVERY_PORT = 8421;
const DISCOVERY_MAGIC = "PCCONNECTOR_DISCOVER";
const PUBLIC_DIR = path.join(__dirname, "public");

const app = express();
app.disable("x-powered-by");

// ---------------------------------------------------------------------------
// 1) Reverse proxy to the PC agent  (must run BEFORE any body parser)
// ---------------------------------------------------------------------------
const proxy = httpProxy.createProxyServer({
  changeOrigin: true,
  proxyTimeout: 60000,
});

proxy.on("error", (err, _req, res) => {
  if (res.headersSent || res.writableEnded) return;
  res.writeHead(502, { "Content-Type": "application/json" });
  res.end(JSON.stringify({ error: "agent_unreachable", detail: err.message }));
});

/** Validate a client-supplied agent base URL to reduce SSRF risk. */
function safeBase(raw) {
  if (!raw) return null;
  let url;
  try {
    url = new URL(raw);
  } catch {
    return null;
  }
  if (url.protocol !== "http:" && url.protocol !== "https:") return null;
  return `${url.protocol}//${url.host}`;
}

app.use("/proxy", (req, res) => {
  // Target agent: from header (XHR) or from query (__base for <img>/<a>).
  const base = safeBase(req.headers["x-agent-base"] || req.query.__base);
  if (!base) {
    res.status(400).json({ error: "missing_or_invalid_agent_base" });
    return;
  }

  // Token: from Authorization header (XHR) or __token query (<img>/<a>).
  if (!req.headers["authorization"] && req.query.__token) {
    req.headers["authorization"] = `Bearer ${req.query.__token}`;
  }
  // Never forward our internal helper header.
  delete req.headers["x-agent-base"];

  proxy.web(req, res, { target: base });
});

// ---------------------------------------------------------------------------
// 2) Wake-on-LAN
// ---------------------------------------------------------------------------
function buildMagicPacket(mac) {
  const clean = String(mac).replace(/[-:\s]/g, "");
  if (!/^[0-9a-fA-F]{12}$/.test(clean)) {
    throw new Error(`Invalid MAC address: ${mac}`);
  }
  const macBytes = Buffer.from(clean, "hex");
  const packet = Buffer.alloc(6 + 16 * 6, 0xff);
  for (let i = 0; i < 16; i++) {
    macBytes.copy(packet, 6 + i * 6);
  }
  return packet;
}

app.post("/api/wol", express.json(), (req, res) => {
  const { mac, broadcast = "255.255.255.255", port = 9 } = req.body || {};
  let packet;
  try {
    packet = buildMagicPacket(mac);
  } catch (e) {
    res.status(400).json({ success: false, error: e.message });
    return;
  }
  const socket = dgram.createSocket("udp4");
  socket.bind(() => {
    socket.setBroadcast(true);
    socket.send(packet, 0, packet.length, port, broadcast, (err) => {
      socket.close();
      if (err) {
        res.status(500).json({ success: false, error: err.message });
      } else {
        res.json({ success: true });
      }
    });
  });
});

// ---------------------------------------------------------------------------
// 3) LAN discovery (UDP broadcast, same protocol as the mobile app)
// ---------------------------------------------------------------------------
app.get("/api/discover", (_req, res) => {
  const socket = dgram.createSocket("udp4");
  const agents = [];
  const seen = new Set();
  let finished = false;

  const finish = () => {
    if (finished) return;
    finished = true;
    try {
      socket.close();
    } catch {
      /* ignore */
    }
    res.json(agents);
  };

  socket.on("message", (data, rinfo) => {
    try {
      const j = JSON.parse(data.toString());
      const key = `${rinfo.address}:${j.port}`;
      if (!seen.has(key)) {
        seen.add(key);
        agents.push({
          name: j.name,
          ip: rinfo.address,
          port: j.port,
          mac: j.mac,
        });
      }
    } catch {
      /* ignore malformed responses */
    }
  });
  socket.on("error", finish);

  socket.bind(() => {
    socket.setBroadcast(true);
    const msg = Buffer.from(DISCOVERY_MAGIC);
    socket.send(msg, 0, msg.length, DISCOVERY_PORT, "255.255.255.255");
  });

  setTimeout(finish, 3000);
});

// ---------------------------------------------------------------------------
// 4) Static Angular SPA + client-side routing fallback
// ---------------------------------------------------------------------------
app.use(express.static(PUBLIC_DIR));
app.get("*", (_req, res) => {
  res.sendFile(path.join(PUBLIC_DIR, "index.html"));
});

app.listen(PORT, () => {
  console.log(`PC Connector web server listening on http://0.0.0.0:${PORT}`);
});
