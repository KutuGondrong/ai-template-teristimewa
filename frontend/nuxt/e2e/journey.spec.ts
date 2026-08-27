import { test, expect } from "@playwright/test";

const email = process.env.E2E_EMAIL ?? "e2e@example.com";
const password = process.env.E2E_PASSWORD ?? "Password1";

test("guest auth logout login chat journey", async ({ page }) => {
  await page.goto("/");
  await expect(page.getByTestId("guest-banner")).toBeVisible();
  await expect(page.getByTestId("nav-login")).toBeVisible();
  await expect(page.getByTestId("chat-input")).toBeVisible();
  await expect(page.getByTestId("nav-chat")).toHaveClass(/is-active/);

  await page.getByTestId("nav-about").click();
  await expect(page.getByTestId("about-page")).toBeVisible();
  await expect(page.getByTestId("nav-about")).toHaveClass(/is-active/);
  await expect(page.getByTestId("chat-input")).toHaveCount(0);

  await page.getByTestId("nav-login").click();
  await expect(page.getByTestId("auth-form")).toBeVisible();
  await expect(page.getByTestId("nav-login")).toHaveCount(0);

  await page.getByTestId("nav-chat").click();
  await expect(page.getByTestId("chat-input")).toBeVisible();
  await expect(page.getByTestId("nav-chat")).toHaveClass(/is-active/);

  await page.getByTestId("nav-login").click();
  await page.getByTestId("auth-email").fill(email);
  await page.getByTestId("auth-password").fill(password);
  await page.getByTestId("auth-submit").click();

  if (await page.getByTestId("auth-error").isVisible().catch(() => false)) {
    await page.getByTestId("nav-signup").click();
    await page.getByTestId("auth-email").fill(email);
    await page.getByTestId("auth-password").fill(password);
    await page.getByTestId("auth-submit").click();
    await expect(page.getByTestId("auth-success")).toBeVisible({ timeout: 30_000 });
    await page.getByTestId("auth-email").fill(email);
    await page.getByTestId("auth-password").fill(password);
    await page.getByTestId("auth-submit").click();
  }

  await expect(page.getByTestId("auth-logout")).toBeVisible({ timeout: 30_000 });
  await expect(page.getByTestId("nav-profile")).toHaveCount(0);

  const marker = `halo-e2e-${Date.now()}`;
  await page.getByTestId("chat-input").fill(marker);
  await page.getByTestId("chat-send").click();
  await expect(page.getByTestId("chat-input")).toBeDisabled();
  await expect(page.getByTestId("chat-input")).toBeEnabled({ timeout: 120_000 });
  await expect(page.getByTestId("chat-list")).toContainText(marker);

  await page.getByTestId("auth-logout").click();
  await expect(page.getByTestId("nav-login")).toBeVisible();
  await expect(page.getByTestId("guest-banner")).toBeVisible();

  await page.getByTestId("nav-login").click();
  await page.getByTestId("auth-email").fill(email);
  await page.getByTestId("auth-password").fill(password);
  await page.getByTestId("auth-submit").click();
  await expect(page.getByTestId("auth-logout")).toBeVisible({ timeout: 30_000 });
  await expect(page.getByTestId("nav-profile")).toHaveCount(0);
  await expect(page.getByTestId("chat-list")).toContainText(marker);
});
