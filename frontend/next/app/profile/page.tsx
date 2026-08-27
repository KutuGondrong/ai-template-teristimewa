"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { useTranslation } from "react-i18next";
import { applySignedOut, authApi } from "@/src/application/session";
import { useSession } from "@/src/presentation/components/SessionProvider";
import { AppButton } from "@/src/presentation/components/AppButton";
import { AppIcon } from "@/src/presentation/components/AppIcon";

export default function ProfilePage() {
  const { t } = useTranslation();
  const router = useRouter();
  const { user, setUser, setChat } = useSession();
  const [ready, setReady] = useState(false);
  const isGuest = !user || user.guest || !user.email;

  useEffect(() => {
    void (async () => {
      const me = await authApi.me();
      setUser(me);
      setReady(true);
      if (!me || me.guest || !me.email) router.replace("/login");
    })();
  }, [router, setUser]);

  async function logout() {
    await applySignedOut(
      (next) => setUser(next),
      (next) => setChat(next),
    );
    router.push("/");
  }

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
      <AppButton variant="outline" data-testid="auth-logout" onClick={() => void logout()}>
        <AppIcon name="logout" />
        {t("nav.logout")}
      </AppButton>
    </article>
  );
}
