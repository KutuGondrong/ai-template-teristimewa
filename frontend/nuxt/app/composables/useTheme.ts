export function applyTheme(theme: "dark" | "light") {
  document.documentElement.classList.toggle("dark", theme === "dark");
  localStorage.setItem("theme", theme);
}

export function readTheme(): "dark" | "light" {
  const stored = localStorage.getItem("theme");
  return stored === "light" ? "light" : "dark";
}

export function useTheme() {
  const theme = useState<"dark" | "light">("theme", () => "dark");

  onMounted(() => {
    theme.value = readTheme();
    applyTheme(theme.value);
  });

  function set(next: "dark" | "light") {
    theme.value = next;
    applyTheme(next);
  }

  function toggle() {
    set(theme.value === "dark" ? "light" : "dark");
  }

  return { theme, set, toggle };
}
