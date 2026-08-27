import { useTranslation } from "react-i18next";

export function LocaleToggle() {
  const { t, i18n } = useTranslation();
  const isId = i18n.language.startsWith("id");

  function choose(next: "id" | "en") {
    void i18n.changeLanguage(next);
    localStorage.setItem("locale", next);
  }

  return (
    <div className="seg-toggle" role="group" aria-label={t("nav.language")} data-testid="lang-switch">
      <button type="button" className={isId ? "is-active" : ""} aria-pressed={isId} onClick={() => choose("id")}>
        ID
      </button>
      <button type="button" className={!isId ? "is-active" : ""} aria-pressed={!isId} onClick={() => choose("en")}>
        EN
      </button>
    </div>
  );
}
