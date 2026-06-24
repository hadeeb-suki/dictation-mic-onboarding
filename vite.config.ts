import * as path from "node:path";

import { defineConfig } from "vite";
import tailwindcss from "@tailwindcss/vite";
import babel from "@rolldown/plugin-babel";

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
  plugins: [babel({ plugins: ["babel-plugin-react-compiler"] }), tailwindcss()],
  base: process.env.GITHUB_ACTIONS ? "/dictation-mic-onboarding/" : "/",
  build: { modulePreload: false },
});
