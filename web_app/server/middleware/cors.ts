export default defineEventHandler((event) => {
  setResponseHeaders(event, {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET,POST,PUT,DELETE,PATCH,OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Agent-Base",
    "Access-Control-Max-Age": "86400",
  });

  if (event.method === "OPTIONS") {
    setResponseStatus(event, 204);
    return "";
  }
});
