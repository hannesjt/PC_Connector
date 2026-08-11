const { app, BrowserWindow, shell } = require("electron");
const path = require("node:path");
const { spawn } = require("node:child_process");

const isDev = process.env.ELECTRON_DEV === "1";
const PORT = process.env.PC_CONNECTOR_PORT || "8099";
const DEV_URL = process.env.NUXT_DEV_URL || "http://localhost:3000";

let serverProcess = null;

function serverEntry() {
  return app.isPackaged
    ? path.join(process.resourcesPath, "output", "server", "index.mjs")
    : path.join(__dirname, "..", ".output", "server", "index.mjs");
}

function startServer() {
  serverProcess = spawn(process.execPath, [serverEntry()], {
    env: {
      ...process.env,
      ELECTRON_RUN_AS_NODE: "1",
      PORT,
      NITRO_PORT: PORT,
    },
    stdio: "inherit",
    windowsHide: true,
  });
  serverProcess.on("error", (err) => console.error("Nitro server error:", err));
}

async function waitForServer(url, timeoutMs = 15000) {
  const start = Date.now();
  while (Date.now() - start < timeoutMs) {
    try {
      const res = await fetch(url);
      if (res.ok || res.status < 500) return true;
    } catch {}
    await new Promise((r) => setTimeout(r, 300));
  }
  return false;
}

function createWindow(url) {
  const win = new BrowserWindow({
    width: 460,
    height: 820,
    minWidth: 380,
    minHeight: 600,
    title: "PC Connector",
    icon: path.join(__dirname, "..", "public", "icon.png"),
    webPreferences: {
      preload: path.join(__dirname, "preload.cjs"),
      contextIsolation: true,
      nodeIntegration: false,
    },
  });

  win.webContents.setWindowOpenHandler(({ url: target }) => {
    shell.openExternal(target);
    return { action: "deny" };
  });

  win.loadURL(url);
}

app.whenReady().then(async () => {
  let url = DEV_URL;
  if (!isDev) {
    startServer();
    url = `http://localhost:${PORT}`;
    await waitForServer(url);
  }
  createWindow(url);

  app.on("activate", () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow(url);
  });
});

app.on("window-all-closed", () => {
  if (process.platform !== "darwin") app.quit();
});

app.on("quit", () => {
  if (serverProcess) serverProcess.kill();
});
