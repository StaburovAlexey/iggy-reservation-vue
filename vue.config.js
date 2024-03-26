const { defineConfig } = require("@vue/cli-service");
module.exports = defineConfig({
  transpileDependencies: true,
  lintOnSave: false,
  pwa: {
    name: "Iggy Reserve",
    themeColor: "#283593",
    msTileColor: "#283593",
    appleMobileWebAppCapable: "yes",
    appleMobileWebAppStatusBarStyle: "black",
    icons: [
      {
        src: "./img/icons/android-chrome-192x192.png",
        sizes: "192x192",
        type: "image/png",
      },
      {
        src: "./img/icons/android-chrome-512x512.png",
        sizes: "512x512",
        type: "image/png",
      },
      {
        src: "./img/icons/android-chrome-maskable-192x192.png",
        sizes: "192x192",
        type: "image/png",
        purpose: "maskable",
      },
      {
        src: "./img/icons/android-chrome-maskable-512x512.png",
        sizes: "512x512",
        type: "image/png",
        purpose: "maskable",
      },
    ],

    iconPaths: {
      faviconSVG: "",
      favicon32: ".img/icons/favicon-32x32.png",
      favicon16: ".img/icons/favicon-16x16.png",
      appleTouchIcon: ".img/icons/apple-touch-icon.png",
      maskIcon: ".img/icons/safari-pinned-tab.svg",
      msTileImage: ".img/icons/mstile-150x150.png",
    },
  },
});
