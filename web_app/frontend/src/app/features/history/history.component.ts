import { Component, inject, signal } from "@angular/core";
import { Router } from "@angular/router";
import { ApiService } from "../../core/services/api.service";
import { ProfileService } from "../../core/services/profile.service";
import { ToastService } from "../../core/services/toast.service";
import { PcProfile } from "../../core/models/pc-profile.model";

interface HistoryEntry {
  script_id: string;
  script_name: string;
  success: boolean;
  exit_code: number;
  timestamp: number;
  stderr: string;
}

@Component({
  selector: "app-history",
  standalone: true,
  template: `
    <header class="app-bar">
      <button class="icon-btn" (click)="back()">←</button>
      <h1 class="app-bar__title">Skript-Verlauf</h1>
      <button class="icon-btn" title="Aktualisieren" (click)="load()">
        🔄
      </button>
      <button class="icon-btn" title="Leeren" (click)="clear()">🗑️</button>
    </header>

    <div class="page">
      @if (loading()) {
        <div class="empty"><span class="spin">🔄</span> Lädt…</div>
      } @else if (entries().length === 0) {
        <div class="empty">Noch keine Ausführungen.</div>
      }

      @for (e of entries(); track $index) {
        <div
          class="card"
          style="display:flex;align-items:center;gap:12px;margin-top:10px"
        >
          <span style="font-size:1.3rem">{{ e.success ? "✅" : "❌" }}</span>
          <div style="flex:1;min-width:0">
            <div style="font-weight:600">{{ e.script_name }}</div>
            <div class="muted" style="font-size:0.78rem">
              {{ format(e.timestamp) }} · Exit {{ e.exit_code }}
            </div>
            @if (e.stderr) {
              <div style="color:var(--danger);font-size:0.78rem;margin-top:4px">
                {{ e.stderr }}
              </div>
            }
          </div>
        </div>
      }
    </div>
  `,
})
export class HistoryComponent {
  private api = inject(ApiService);
  private profiles = inject(ProfileService);
  private router = inject(Router);
  private toast = inject(ToastService);

  readonly profile = signal<PcProfile | undefined>(undefined);
  readonly entries = signal<HistoryEntry[]>([]);
  readonly loading = signal(false);

  constructor() {
    const id = this.router.url.split("/")[2] ?? "";
    this.profile.set(this.profiles.getById(id));
    if (this.profile()) this.load();
  }

  async load(): Promise<void> {
    const p = this.profile();
    if (!p) return;
    this.loading.set(true);
    try {
      this.entries.set((await this.api.getHistory(p)) as HistoryEntry[]);
    } finally {
      this.loading.set(false);
    }
  }

  async clear(): Promise<void> {
    const p = this.profile();
    if (!p || !confirm("Gesamten Verlauf löschen?")) return;
    try {
      await this.api.clearHistory(p);
      this.entries.set([]);
      this.toast.show("Verlauf geleert");
    } catch {
      this.toast.show("Fehlgeschlagen");
    }
  }

  format(ts: number): string {
    return new Date(ts * 1000).toLocaleString("de-DE");
  }

  back(): void {
    const p = this.profile();
    this.router.navigate(p ? ["/pc", p.id] : ["/"]);
  }
}
