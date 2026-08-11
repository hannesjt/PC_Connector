const KEY = "pc_connector_theme";

export function useTheme() {
  const dark = useState<boolean>("theme-dark", () => true);

  function apply(): void {
    if (import.meta.client) {
      document.documentElement.classList.toggle("dark", dark.value);
      localStorage.setItem(KEY, dark.value ? "dark" : "light");
    }
  }

  function init(): void {
    if (!import.meta.client) return;
    const stored = localStorage.getItem(KEY);
    if (stored) {
      dark.value = stored === "dark";
    } else {
      dark.value =
        window.matchMedia?.("(prefers-color-scheme: dark)").matches ?? true;
    }
    apply();
  }

  function toggle(): void {
    dark.value = !dark.value;
    apply();
  }

  return { dark, init, toggle };
}
