"use client";

import { useState } from "react";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { useTranslation } from "react-i18next";
import { isStrongPassword, isValidEmail } from "@/src/shared";
import { applySignedIn, authApi } from "@/src/application/session";
import { useSession } from "@/src/presentation/components/SessionProvider";
import { AppButton } from "@/src/presentation/components/AppButton";
import { AppLogo } from "@/src/presentation/components/AppLogo";

export function AuthForm({ mode }: { mode: "login" | "signup" }) {
  const { t } = useTranslation();
  const router = useRouter();
  const search = useSearchParams();
  const { setUser, setChat } = useSession();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const justRegistered = mode === "login" && search.get("registered") === "1";

  async function submit() {
    setError("");
    const e = email.trim().toLowerCase();
    if (!isValidEmail(e)) {
      setError(t("auth.invalidEmail"));
      return;
    }
    if (mode === "signup" && !isStrongPassword(password)) {
      setError(t("auth.weakPassword"));
      return;
    }
    try {
      if (mode === "signup") {
        await authApi.signup(e, password);
        router.push("/login?registered=1");
        return;
      }
      const user = await authApi.login(e, password);
      await applySignedIn(
        user,
        (next) => setUser(next),
        (next) => setChat(next),
      );
      router.push("/");
    } catch (err: unknown) {
      const status = (err as { response?: { status?: number } })?.response?.status;
      if (status === 409) setError(t("auth.emailTaken"));
      else if (status === 401) setError(t("auth.wrongCredentials"));
      else setError(t("errors.network"));
    }
  }

  return (
    <div className="flex flex-1 items-center py-8">
      <form
        className="auth-card mx-auto flex flex-col gap-4"
        data-testid="auth-form"
        onSubmit={(ev) => {
          ev.preventDefault();
          void submit();
        }}
      >
        <div className="flex flex-col items-center text-center">
          <AppLogo size="lg" />
          <h1 className="mt-3 font-display text-2xl font-semibold">{mode === "login" ? t("nav.login") : t("nav.signup")}</h1>
          <p className="mt-1 text-sm text-muted-foreground">
            {mode === "login" ? t("auth.subtitleLogin") : t("auth.subtitleSignup")}
          </p>
        </div>
        <label className="text-sm">
          {t("auth.email")}
          <input data-testid="auth-email" type="email" className="field" value={email} onChange={(e) => setEmail(e.target.value)} />
        </label>
        <label className="text-sm">
          {t("auth.password")}
          <input
            data-testid="auth-password"
            type="password"
            className="field"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
          />
        </label>
        {justRegistered && !error ? (
          <p className="text-sm text-primary" data-testid="auth-success">
            {t("auth.signupSuccess")}
          </p>
        ) : null}
        {error ? (
          <p className="text-sm text-destructive" data-testid="auth-error">
            {error}
          </p>
        ) : null}
        <AppButton type="submit" data-testid="auth-submit">
          {mode === "login" ? t("auth.submitLogin") : t("auth.submitSignup")}
        </AppButton>
        <p className="text-center text-sm text-muted-foreground">
          {mode === "login" ? (
            <>
              {t("auth.noAccount")}{" "}
              <Link href="/signup" className="text-primary" data-testid="nav-signup">
                {t("nav.signup")}
              </Link>
            </>
          ) : (
            <>
              {t("auth.haveAccount")}{" "}
              <Link href="/login" className="text-primary">
                {t("nav.login")}
              </Link>
            </>
          )}
        </p>
      </form>
    </div>
  );
}
