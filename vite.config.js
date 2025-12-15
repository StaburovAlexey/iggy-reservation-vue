import { defineConfig } from "vite";
import vue from "@vitejs/plugin-vue";
import { VitePWA } from "vite-plugin-pwa";
import path from "path";

export default defineConfig({
  plugins: [
    vue(),
    VitePWA({
      registerType: "autoUpdate",
      includeAssets: ["favicon.ico", "apple-touch-icon.png", "safari-pinned-tab.svg"],
      manifest: false, // Используем существующий manifest.json
      includeManifestIcons: false,
      workbox: {
        globPatterns: ["**/*.{js,css,html,png,svg,ico,woff2}"],
        cleanupOutdatedCaches: true,
        clientsClaim: true,
        skipWaiting: true,
      },
      devOptions: {
        enabled: process.env.NODE_ENV === "development",
        type: "module",
        navigateFallback: "index.html",
      },
    }),
  ],
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "src"),
    },
  },
});
