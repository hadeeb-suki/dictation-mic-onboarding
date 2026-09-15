import * as path from "node:path";

import { defineConfig } from "vite";
import tailwindcss from "@tailwindcss/vite";
import react from "@vitejs/plugin-react";

// https://vite.dev/config/
export default defineConfig({
  resolve: {
    alias: {
      "react/compiler-runtime": path.resolve("./src/compiler-runtime.ts"),
      "react/jsx-runtime": "preact/jsx-runtime",
      "react/jsx-dev-runtime": "preact/jsx-runtime",
      react: "preact/hooks",
    },
  },
  plugins: [react({ compiler: true }), tailwindcss()],
  base: process.env.GITHUB_ACTIONS ? "/dictation-mic-onboarding/" : "/",
  build: { modulePreload: false },
});
