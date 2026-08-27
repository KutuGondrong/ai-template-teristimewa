import { useEffect, useState } from "react";

export type Theme = "dark" | "light";

export function applyTheme(theme: Theme) {
  document.documentElement.classList.toggle("dark", theme === "dark");
  localStorage.setItem("theme", theme);
}

export function readTheme(): Theme {
  return localStorage.getItem("theme") === "light" ? "light" : "dark";
}

export function useTheme() {
  const [theme, setTheme] = useState<Theme>("dark");

  useEffect(() => {
    const next = readTheme();
    setTheme(next);
    applyTheme(next);
  }, []);

  function set(next: Theme) {
    setTheme(next);
    applyTheme(next);
  }

  function toggle() {
    set(theme === "dark" ? "light" : "dark");
  }

  return { theme, set, toggle };
}
