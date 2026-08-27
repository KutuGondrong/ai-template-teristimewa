import { defineConfig, devices } from "@playwright/test";
import fs from "node:fs";
import path from "node:path";

const envPath = path.resolve("e2e.env");
if (fs.existsSync(envPath)) {
  for (const line of fs.readFileSync(envPath, "utf8").split("\n")) {
    const m = line.match(/^([^#=]+)=(.*)$/);
    if (m) process.env[m[1].trim()] ??= m[2].trim();
  }
}

const baseURL = process.env.E2E_BASE_URL ?? "http://127.0.0.1:3000";

export default defineConfig({
  testDir: "./e2e",
  timeout: 120_000,
  use: { ...devices["Desktop Chrome"], baseURL, trace: "on-first-retry" },
  webServer: process.env.E2E_NO_WEBSERVER
    ? undefined
    : {
        command: "pnpm preview",
        url: baseURL,
        reuseExistingServer: true,
        timeout: 120_000,
      },
});
