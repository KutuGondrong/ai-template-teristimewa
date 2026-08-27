import { onMounted, ref } from "vue";

export function applyTheme(theme: "dark" | "light") {
  document.documentElement.classList.toggle("dark", theme === "dark");
  localStorage.setItem("theme", theme);
}

export function readTheme(): "dark" | "light" {
  return localStorage.getItem("theme") === "light" ? "light" : "dark";
}

export function useTheme() {
  const theme = ref<"dark" | "light">("dark");

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
