import { useEffect, useState } from "react";
import { NavLink, Route, Routes, useLocation, useNavigate } from "react-router-dom";
import { useTranslation } from "react-i18next";
import type { User } from "@/shared";
import { applySignedIn, applySignedOut, hydrateSession, initialChat } from "./application/session";
import type { ChatState } from "@/shared";
import { ChatPage } from "./presentation/pages/ChatPage";
import { AuthPage } from "./presentation/pages/AuthPage";
import { AboutPage } from "./presentation/pages/AboutPage";
import { ProfilePage } from "./presentation/pages/ProfilePage";
import { AppIcon } from "./presentation/components/AppIcon";
import { AppLogo } from "./presentation/components/AppLogo";
import { LocaleToggle } from "./presentation/components/LocaleToggle";
import { ThemeToggle } from "./presentation/components/ThemeToggle";

function navClass(base: string, active: boolean) {
  return active ? `${base} is-active` : base;
}

export function App() {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const location = useLocation();
  const [user, setUser] = useState<User | null>(null);
  const [ready, setReady] = useState(false);
  const [chat, setChat] = useState<ChatState>(initialChat);

  useEffect(() => {
    void (async () => {
      await hydrateSession(
        (next) => setUser(next),
        (next) => setChat(next),
      );
      setReady(true);
    })();
  }, []);

  const isGuest = !user || user.guest || !user.email;
  const showGuestNotice = Boolean(user && (user.guest || !user.email));
  const onLogin = location.pathname.replace(/\/$/, "") === "/login";

  async function logout() {
    await applySignedOut(
      (next) => setUser(next),
      (next) => setChat(next),
    );
    navigate("/");
  }

  return (
    <div className="app-canvas">
      <header className="app-header">
        <div className="app-header-inner">
          <NavLink to="/" className="app-brand">
            <AppLogo />
            <div>
              <p className="font-display text-base font-semibold tracking-tight">{t("app.name")}</p>
              <p className="text-xs text-muted-foreground">{t("app.tagline")}</p>
            </div>
          </NavLink>
          <nav className="app-header-nav" aria-label={t("nav.chat")}>
            <NavLink
              to="/"
              end
              className={({ isActive }) => navClass("btn btn-ghost", isActive)}
              data-testid="nav-chat"
            >
              <AppIcon name="chat" />
              {t("nav.chat")}
            </NavLink>
            <NavLink
              to="/about"
              className={({ isActive }) => navClass("btn btn-ghost", isActive)}
              data-testid="nav-about"
            >
              <AppIcon name="about" />
              {t("nav.about")}
            </NavLink>
            <ThemeToggle />
            <LocaleToggle />
          </nav>
          <div className="app-header-auth">
            {isGuest && !onLogin ? (
              <NavLink
                to="/login"
                className="btn btn-outline"
                data-testid="nav-login"
              >
                <AppIcon name="login" />
                {t("nav.login")}
              </NavLink>
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
      <main className="app-main">
        <Routes>
          <Route path="/" element={<ChatPage chat={chat} setChat={setChat} isGuest={showGuestNotice} />} />
          <Route
            path="/login"
            element={
              <AuthPage
                mode="login"
                onAuth={(u) => applySignedIn(u, (n) => setUser(n), (n) => setChat(n))}
              />
            }
          />
          <Route
            path="/signup"
            element={<AuthPage mode="signup" onAuth={(u) => void applySignedIn(u, (n) => setUser(n), (n) => setChat(n))} />}
          />
          <Route path="/about" element={<AboutPage />} />
          <Route path="/profile" element={<ProfilePage user={user} ready={ready} onLogout={logout} />} />
        </Routes>
      </main>
    </div>
  );
}
