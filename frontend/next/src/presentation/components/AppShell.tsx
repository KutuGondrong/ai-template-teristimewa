"use client";

import Link from "next/link";
import { useEffect, type ReactNode } from "react";
import { usePathname, useRouter } from "next/navigation";
import { useTranslation } from "react-i18next";
import { syncLocaleFromStorage } from "@/src/i18n";
import { applySignedOut, hydrateSession } from "@/src/application/session";
import { SessionProvider, useSession } from "@/src/presentation/components/SessionProvider";
import { AppIcon } from "@/src/presentation/components/AppIcon";
import { AppLogo } from "@/src/presentation/components/AppLogo";
import { LocaleToggle } from "@/src/presentation/components/LocaleToggle";
import { ThemeToggle } from "@/src/presentation/components/ThemeToggle";

function isNavActive(pathname: string, path: string) {
  const current = pathname.replace(/\/$/, "") || "/";
  if (path === "/") return current === "/";
  return current === path || current.startsWith(`${path}/`);
}

function navClass(base: string, active: boolean) {
  return active ? `${base} is-active` : base;
}

function Header() {
  const { t } = useTranslation();
  const pathname = usePathname();
  const router = useRouter();
  const { user, setUser, setChat } = useSession();
  const isGuest = !user || user.guest || !user.email;
  const onLogin = isNavActive(pathname, "/login");

  async function logout() {
    await applySignedOut(
      (next) => setUser(next),
      (next) => setChat(next),
    );
    router.push("/");
  }

  return (
    <header className="app-header">
      <div className="app-header-inner">
        <Link href="/" className="app-brand">
          <AppLogo />
          <div>
            <p className="font-display text-base font-semibold tracking-tight">{t("app.name")}</p>
            <p className="text-xs text-muted-foreground">{t("app.tagline")}</p>
          </div>
        </Link>
        <nav className="app-header-nav" aria-label={t("nav.chat")}>
          <Link
            href="/"
            className={navClass("btn btn-ghost", isNavActive(pathname, "/"))}
            aria-current={isNavActive(pathname, "/") ? "page" : undefined}
            data-testid="nav-chat"
          >
            <AppIcon name="chat" />
            {t("nav.chat")}
          </Link>
          <Link
            href="/about"
            className={navClass("btn btn-ghost", isNavActive(pathname, "/about"))}
            aria-current={isNavActive(pathname, "/about") ? "page" : undefined}
            data-testid="nav-about"
          >
            <AppIcon name="about" />
            {t("nav.about")}
          </Link>
          <ThemeToggle />
          <LocaleToggle />
        </nav>
        <div className="app-header-auth">
          {isGuest && !onLogin ? (
            <Link
              href="/login"
              className="btn btn-outline"
              data-testid="nav-login"
            >
              <AppIcon name="login" />
              {t("nav.login")}
            </Link>
          ) : !isGuest ? (
            <button
              type="button"
              className="btn btn-outline"
              data-testid="auth-logout"
              onClick={() => void logout()}
            >
              <AppIcon name="logout" />
              {t("nav.logout")}
            </button>
          ) : null}
        </div>
      </div>
    </header>
  );
}

function Bootstrap({ children }: { children: ReactNode }) {
  const { setUser, setChat } = useSession();
  useEffect(() => {
    syncLocaleFromStorage();
    void hydrateSession(
      (next) => setUser(next),
      (next) => setChat(next),
    );
  }, [setUser, setChat]);
  return <>{children}</>;
}

function ShellBody({ children }: { children: ReactNode }) {
  return (
    <>
      <Header />
      <main className="app-main">{children}</main>
    </>
  );
}

export function AppShell({ children }: { children: ReactNode }) {
  return (
    <SessionProvider>
      <div className="app-canvas">
        <Bootstrap>
          <ShellBody>{children}</ShellBody>
        </Bootstrap>
      </div>
    </SessionProvider>
  );
}
