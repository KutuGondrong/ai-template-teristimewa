import { useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { useTranslation } from "react-i18next";
import type { User } from "@/shared";
import { AppButton } from "../components/AppButton";
import { AppIcon } from "../components/AppIcon";

export function ProfilePage({
  user,
  ready,
  onLogout,
}: {
  user: User | null;
  ready: boolean;
  onLogout: () => Promise<void>;
}) {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const isGuest = !user || user.guest || !user.email;

  useEffect(() => {
    if (ready && isGuest) navigate("/login", { replace: true });
  }, [ready, isGuest, navigate]);

  if (!ready || isGuest || !user) return null;

  return (
    <article className="auth-card mx-auto space-y-4" data-testid="profile-page">
      <div className="flex items-center gap-3">
        <span className="profile-avatar profile-avatar-lg">{user.email[0].toUpperCase()}</span>
        <h1 className="font-display text-2xl font-semibold">{t("profile.title")}</h1>
      </div>
      <dl className="grid grid-cols-2 gap-2 text-sm">
        <dt className="text-muted-foreground">{t("profile.email")}</dt>
        <dd data-testid="profile-email">{user.email}</dd>
        <dt className="text-muted-foreground">{t("profile.id")}</dt>
        <dd data-testid="profile-id">{user.id}</dd>
      </dl>
      <AppButton variant="outline" data-testid="auth-logout" onClick={() => void onLogout()}>
        <AppIcon name="logout" />
        {t("nav.logout")}
      </AppButton>
    </article>
  );
}
