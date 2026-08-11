export default defineNuxtConfig({
  compatibilityDate: "2024-11-01",
  ssr: false,
  devtools: { enabled: false },

  app: {
    baseURL: process.env.NUXT_APP_BASE_URL || "/",
    buildAssetsDir: "assets",
    head: {
      title: "PC Connector",
      meta: [
        { charset: "utf-8" },
        {
          name: "viewport",
          content: "width=device-width, initial-scale=1, viewport-fit=cover",
        },
        { name: "theme-color", content: "#1976D2" },
        { name: "color-scheme", content: "light dark" },
      ],
      htmlAttrs: { lang: "de" },
    },
  },

  css: ["~/assets/css/main.css"],

  runtimeConfig: {
    public: {
      backendBase: process.env.NUXT_PUBLIC_BACKEND_BASE || "",
    },
  },

  nitro: {
    preset: "node-server",
  },

  experimental: {
    appManifest: false,
  },
});
