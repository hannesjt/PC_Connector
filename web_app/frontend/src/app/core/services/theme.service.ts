import { Injectable, effect, signal } from "@angular/core";

const KEY = "pc_connector_theme";

@Injectable({ providedIn: "root" })
export class ThemeService {
  readonly dark = signal<boolean>(this.initial());

  constructor() {
    effect(() => {
      const d = this.dark();
      document.documentElement.classList.toggle("dark", d);
      localStorage.setItem(KEY, d ? "dark" : "light");
    });
  }

  private initial(): boolean {
    const stored = localStorage.getItem(KEY);
    if (stored) return stored === "dark";
    return window.matchMedia?.("(prefers-color-scheme: dark)").matches ?? true;
  }

  toggle(): void {
    this.dark.set(!this.dark());
  }
}
