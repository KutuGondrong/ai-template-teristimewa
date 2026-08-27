import { useEffect, useState } from "react";
import { useTranslation } from "react-i18next";
import type { LlmActive } from "@/shared";

export function AboutPage() {
  const { t, i18n } = useTranslation();
  const [llm, setLlm] = useState<LlmActive | null>(null);

  useEffect(() => {
    void fetch("/llm.active.json")
      .then((r) => r.json())
      .then((data: LlmActive) => setLlm(data))
      .catch(() => setLlm(null));
  }, []);

  return (
    <div className="about-page" data-testid="about-page">
      <section className="about-section" data-testid="about-model">
        <h2>{t("about.title")}</h2>
        {llm ? (
          <>
            <p className="about-lead">
              {llm.name} {llm.version}
            </p>
            <p className="about-body">{i18n.language === "id" ? llm.about_id : llm.about_en}</p>
            <dl className="mt-4 grid grid-cols-2 gap-2 text-sm">
              <dt className="text-muted-foreground">{t("about.vendor")}</dt>
              <dd>{llm.vendor}</dd>
              <dt className="text-muted-foreground">{t("about.license")}</dt>
              <dd>{llm.license}</dd>
              <dt className="text-muted-foreground">{t("about.weight")}</dt>
              <dd>{llm.weight}</dd>
              <dt className="text-muted-foreground">{t("about.ram")}</dt>
              <dd>{llm.ram_min_gb} GB</dd>
              <dt className="text-muted-foreground">{t("about.cpu")}</dt>
              <dd>{llm.cpu_min_cores}</dd>
              <dt className="text-muted-foreground">{t("about.disk")}</dt>
              <dd>{llm.disk_min_gb} GB</dd>
              <dt className="text-muted-foreground">{t("about.gpu")}</dt>
              <dd>{llm.gpu}</dd>
            </dl>
          </>
        ) : null}
      </section>

      <section className="about-section" data-testid="about-maker">
        <p className="about-body">{t("about.makerBody")}</p>
        <p className="about-links">
          <a
            className="about-link"
            href="https://teristimewa.com/"
            target="_blank"
            rel="noopener noreferrer"
          >
            {t("about.makerStudioCta")}
          </a>
          <a
            className="about-link"
            href="https://hedysimamora.teristimewa.com/"
            target="_blank"
            rel="noopener noreferrer"
          >
            {t("about.makerDevCta")}
          </a>
        </p>
      </section>
    </div>
  );
}
