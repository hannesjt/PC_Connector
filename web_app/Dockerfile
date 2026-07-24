# --- Stage 1: build the Angular SPA ---
FROM node:20-alpine AS build
WORKDIR /app/frontend
COPY frontend/package*.json ./
RUN npm install
COPY frontend/ ./
RUN npm run build

# --- Stage 2: runtime (Node backend serving the SPA) ---
FROM node:20-alpine
WORKDIR /app
ENV NODE_ENV=production
ENV PORT=8080
COPY backend/package*.json ./
RUN npm install --omit=dev
COPY backend/ ./
# Angular's application builder emits into dist/pc-connector-web/browser
COPY --from=build /app/frontend/dist/pc-connector-web/browser ./public
EXPOSE 8080
CMD ["node", "server.js"]
