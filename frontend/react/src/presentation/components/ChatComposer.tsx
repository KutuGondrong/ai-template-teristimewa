import { useTranslation } from "react-i18next";

export function ChatComposer({
  draft,
  pending,
  onDraft,
  onSend,
}: {
  draft: string;
  pending: boolean;
  onDraft: (value: string) => void;
  onSend: () => void;
}) {
  const { t } = useTranslation();
  return (
    <form
      className="composer"
      onSubmit={(e) => {
        e.preventDefault();
        onSend();
      }}
    >
      <input
        data-testid="chat-input"
        className="composer-input"
        value={draft}
        disabled={pending}
        placeholder={t("chat.placeholder")}
        onChange={(e) => onDraft(e.target.value)}
      />
      <button
        type="submit"
        data-testid="chat-send"
        className="composer-send"
        disabled={pending || !draft.trim()}
        aria-label={t("chat.send")}
      >
        <svg viewBox="0 0 24 24" className="h-4 w-4" fill="currentColor">
          <path d="M12 4 5.5 10.5h4.25V20h4.5v-9.5H18.5Z" />
        </svg>
      </button>
    </form>
  );
}
