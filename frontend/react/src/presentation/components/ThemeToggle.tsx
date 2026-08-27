import { useTranslation } from "react-i18next";
import { useTheme } from "../theme";

export function ThemeToggle() {
  const { t } = useTranslation();
  const { theme, set } = useTheme();
  return (
    <div className="seg-toggle seg-toggle-icon" role="group" aria-label={t("nav.theme")} data-testid="theme-toggle">
      <button
        type="button"
        className={theme === "dark" ? "is-active" : ""}
        aria-label={t("theme.dark")}
        aria-pressed={theme === "dark"}
        onClick={() => set("dark")}
      >
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8">
          <path d="M16 12a6 6 0 1 1-8-5.7A7 7 0 0 0 16 12Z" />
        </svg>
      </button>
      <button
        type="button"
        className={theme === "light" ? "is-active" : ""}
        aria-label={t("theme.light")}
        aria-pressed={theme === "light"}
        onClick={() => set("light")}
      >
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8">
          <circle cx="12" cy="12" r="4" />
          <path d="M12 3v2M12 19v2M5 12H3M21 12h-2M6.2 6.2l1.4 1.4M16.4 16.4l1.4 1.4M6.2 17.8l1.4-1.4M16.4 7.6l1.4-1.4" />
        </svg>
      </button>
    </div>
  );
}
