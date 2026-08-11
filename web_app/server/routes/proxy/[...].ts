import { createProxyServer } from "httpxy";

const proxy = createProxyServer({
  changeOrigin: true,
  proxyTimeout: 60000,
});

function safeBase(raw?: string | null): string | null {
  if (!raw) return null;
  let url: URL;
  try {
    url = new URL(raw);
  } catch {
    return null;
  }
  if (url.protocol !== "http:" && url.protocol !== "https:") return null;
  return `${url.protocol}//${url.host}`;
}

export default defineEventHandler(async (event) => {
  const req = event.node.req;
  const res = event.node.res;

  const query = getQuery(event);
  const base = safeBase(
    (req.headers["x-agent-base"] as string) || (query.__base as string),
  );
  if (!base) {
    res.statusCode = 400;
    res.setHeader("Content-Type", "application/json");
    res.end(JSON.stringify({ error: "missing_or_invalid_agent_base" }));
    return;
  }

  if (!req.headers["authorization"] && query.__token) {
    req.headers["authorization"] = `Bearer ${query.__token}`;
  }
  delete req.headers["x-agent-base"];

  if (req.url) req.url = req.url.replace(/^\/proxy/, "") || "/";

  try {
    await proxy.web(req, res, { target: base });
  } catch (err: any) {
    if (!res.headersSent && !res.writableEnded) {
      res.statusCode = 502;
      res.setHeader("Content-Type", "application/json");
      res.end(
        JSON.stringify({ error: "agent_unreachable", detail: err?.message }),
      );
    }
  }
});
