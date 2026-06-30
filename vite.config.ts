import * as path from "node:path";

import { defineConfig } from "vite";
import tailwindcss from "@tailwindcss/vite";
import react from "@vitejs/plugin-react-swc";

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
  plugins: [
    react({
      useAtYourOwnRisk_mutateSwcOptions: (options) => {
        options.jsc.transform.reactCompiler = true;
      },
    }),
    tailwindcss(),
  ],
  base: process.env.GITHUB_ACTIONS ? "/dictation-mic-onboarding/" : "/",
  build: { modulePreload: false },
});
