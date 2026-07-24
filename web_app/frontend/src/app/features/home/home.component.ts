import { Component, computed, inject, signal } from "@angular/core";
import { FormsModule } from "@angular/forms";
import { Router } from "@angular/router";
import { ApiService } from "../../core/services/api.service";
import { ProfileService } from "../../core/services/profile.service";
import { ThemeService } from "../../core/services/theme.service";
import { ToastService } from "../../core/services/toast.service";
import { iconFor } from "../../core/icons";
import { PcProfile } from "../../core/models/pc-profile.model";
import {
  ScriptChain,
  ScriptConfig,
  ScriptResult,
} from "../../core/models/script.model";

interface Group {
  name: string;
  scripts: ScriptConfig[];
}

@Component({
  selector: "app-home",
  standalone: true,
  imports: [FormsModule],
  template: `
    @if (profile(); as p) {
      <header class="app-bar">
        <button class="icon-btn" (click)="router.navigate(['/'])">←</button>
        <div style="flex:1;min-width:0">
          <h1
            class="app-bar__title"
            style="display:flex;align-items:center;gap:8px"
          >
            <span
              class="dot"
              [class.dot--online]="online() === true"
              [class.dot--offline]="online() === false"
            ></span>
            {{ p.name }}
          </h1>
          <div class="app-bar__sub">
            {{ p.ipAddress }}:{{ p.port }} ·
            {{
              online() === true
                ? "online"
                : online() === false
                  ? "offline"
                  : "…"
            }}
          </div>
        </div>
        <button class="icon-btn" title="Aktualisieren" (click)="refresh()">
          🔄
        </button>
        <button class="icon-btn" title="Design" (click)="theme.toggle()">
          {{ theme.dark() ? "☀️" : "🌙" }}
        </button>
      </header>

      <div class="page">
        @if (online() === false) {
          <div class="card" style="text-align:center">
            <div style="font-size:2.2rem">😴</div>
            <p class="muted" style="margin:8px 0 16px">
              PC ist offline oder im Ruhezustand.
            </p>
            <button class="btn btn--primary btn--lg" (click)="wake()">
              ⚡ Aufwecken (Wake-on-LAN)
            </button>
          </div>
        }

        <!-- Quick actions -->
        <div class="card">
          <p class="card__title">Steuerung</p>
          <div class="quick-grid">
            <div class="tile" (click)="go('input')">
              <span class="tile__icon">🖱️</span
              ><span class="tile__label">Maus &amp; Tastatur</span>
            </div>
            <div class="tile" (click)="openVolume()">
              <span class="tile__icon">🔊</span
              ><span class="tile__label">Lautstärke</span>
            </div>
            <div class="tile" (click)="openClipboard()">
              <span class="tile__icon">📋</span
              ><span class="tile__label">Zwischenablage</span>
            </div>
            <div class="tile" (click)="go('screen')">
              <span class="tile__icon">🖥️</span
              ><span class="tile__label">Bildschirm</span>
            </div>
            <div class="tile" (click)="go('files')">
              <span class="tile__icon">📁</span
              ><span class="tile__label">Dateien</span>
            </div>
            <div class="tile" (click)="go('history')">
              <span class="tile__icon">📜</span
              ><span class="tile__label">Verlauf</span>
            </div>
          </div>
        </div>

        <!-- Scripts -->
        @for (g of groups(); track g.name) {
          <div class="card">
            <p class="card__title">{{ g.name || "Skripte" }}</p>
            <div class="grid">
              @for (s of g.scripts; track s.id) {
                <button
                  class="tile"
                  (click)="runScript(s)"
                  [disabled]="running() === s.id"
                >
                  <span class="tile__icon">
                    @if (running() === s.id) {
                      <span class="spin">🔄</span>
                    } @else {
                      {{ icon(s.icon) }}
                    }
                  </span>
                  <span class="tile__label">{{ s.name }}</span>
                </button>
              }
            </div>
          </div>
        }

        <!-- Chains -->
        @if (chains().length) {
          <div class="card">
            <p class="card__title">Abläufe</p>
            @for (c of chains(); track c.id) {
              <button
                class="btn btn--block"
                style="justify-content:flex-start;margin-bottom:8px"
                (click)="runChain(c)"
                [disabled]="running() === c.id"
              >
                @if (running() === c.id) {
                  <span class="spin">🔄</span>
                } @else {
                  🔗
                }
                {{ c.name }}
                <span class="muted" style="margin-left:auto;font-size:0.8rem">
                  {{ c.steps.length }} Schritte
                </span>
              </button>
            }
          </div>
        }

        @if (loaded() && groups().length === 0 && chains().length === 0) {
          <div class="empty">Keine Skripte konfiguriert.</div>
        }
      </div>

      <!-- Script result modal -->
      @if (result(); as r) {
        <div class="modal-backdrop" (click)="result.set(null)">
          <div class="modal" (click)="$event.stopPropagation()">
            <h2 class="modal__title">
              {{ r.success ? "✅ Erfolgreich" : "❌ Fehlgeschlagen" }}
            </h2>
            @if (r.stdout) {
              <p class="muted" style="margin:0 0 4px">Ausgabe</p>
              <pre class="result-pre">{{ r.stdout }}</pre>
            }
            @if (r.stderr) {
              <p class="muted" style="margin:12px 0 4px">Fehler</p>
              <pre class="result-pre" style="color:var(--danger)">{{
                r.stderr
              }}</pre>
            }
            @if (!r.stdout && !r.stderr) {
              <p class="muted">Keine Ausgabe (Exit-Code {{ r.exitCode }}).</p>
            }
            <button
              class="btn btn--primary btn--block"
              style="margin-top:16px"
              (click)="result.set(null)"
            >
              Schließen
            </button>
          </div>
        </div>
      }

      <!-- Volume modal -->
      @if (volumeOpen()) {
        <div class="modal-backdrop" (click)="volumeOpen.set(false)">
          <div class="modal" (click)="$event.stopPropagation()">
            <h2 class="modal__title">🔊 Lautstärke</h2>
            <div class="row">
              <button class="icon-btn" (click)="toggleMute()">
                {{ muted() ? "🔇" : "🔊" }}
              </button>
              <input
                type="range"
                min="0"
                max="100"
                style="flex:1"
                [ngModel]="volume()"
                (ngModelChange)="onVolume($event)"
              />
              <span style="width:44px;text-align:right">{{ volume() }}%</span>
            </div>
            <button
              class="btn btn--block"
              style="margin-top:16px"
              (click)="volumeOpen.set(false)"
            >
              Schließen
            </button>
          </div>
        </div>
      }

      <!-- Clipboard modal -->
      @if (clipOpen()) {
        <div class="modal-backdrop" (click)="clipOpen.set(false)">
          <div class="modal" (click)="$event.stopPropagation()">
            <h2 class="modal__title">📋 Zwischenablage senden</h2>
            <textarea
              class="input"
              [(ngModel)]="clipText"
              placeholder="Text an den PC senden…"
            ></textarea>
            <div class="row" style="margin-top:14px;justify-content:flex-end">
              <button class="btn" (click)="pullClipboard()">
                Vom PC holen
              </button>
              <button class="btn btn--primary" (click)="sendClipboard()">
                Senden
              </button>
            </div>
          </div>
        </div>
      }
    } @else {
      <div class="empty">PC nicht gefunden.</div>
    }
  `,
  styles: [
    `
      .result-pre {
        background: var(--surface-2);
        border: 1px solid var(--border);
        border-radius: 10px;
        padding: 12px;
        max-height: 40vh;
        overflow: auto;
        white-space: pre-wrap;
        word-break: break-word;
        font-size: 0.85rem;
        margin: 0;
      }
    `,
  ],
})
export class HomeComponent {
  protected router = inject(Router);
  protected theme = inject(ThemeService);
  private api = inject(ApiService);
  private profiles = inject(ProfileService);
  private toast = inject(ToastService);

  readonly profile = signal<PcProfile | undefined>(undefined);
  readonly online = signal<boolean | undefined>(undefined);
  readonly scripts = signal<ScriptConfig[]>([]);
  readonly chains = signal<ScriptChain[]>([]);
  readonly categoryOrder = signal<string[]>([]);
  readonly loaded = signal(false);
  readonly running = signal<string | null>(null);
  readonly result = signal<ScriptResult | null>(null);

  readonly volumeOpen = signal(false);
  readonly volume = signal(0);
  readonly muted = signal(false);
  readonly clipOpen = signal(false);
  clipText = "";

  readonly groups = computed<Group[]>(() => {
    const byGroup = new Map<string, ScriptConfig[]>();
    for (const s of [...this.scripts()].sort((a, b) => a.order - b.order)) {
      const list = byGroup.get(s.group) ?? [];
      list.push(s);
      byGroup.set(s.group, list);
    }
    const order = this.categoryOrder();
    const names = [...byGroup.keys()].sort((a, b) => {
      const ia = order.indexOf(a);
      const ib = order.indexOf(b);
      if (ia !== -1 && ib !== -1) return ia - ib;
      if (ia !== -1) return -1;
      if (ib !== -1) return 1;
      return a.localeCompare(b);
    });
    return names.map((name) => ({ name, scripts: byGroup.get(name)! }));
  });

  constructor() {
    const id = this.router.url.split("/")[2]?.split("?")[0] ?? "";
    this.profile.set(this.profiles.getById(id));
    if (this.profile()) this.refresh();
  }

  icon(name: string): string {
    return iconFor(name);
  }

  go(sub: string): void {
    const p = this.profile();
    if (p) this.router.navigate(["/pc", p.id, sub]);
  }

  async refresh(): Promise<void> {
    const p = this.profile();
    if (!p) return;
    this.online.set(await this.api.isOnline(p));
    if (this.online()) {
      try {
        const [scripts, chains, cats] = await Promise.all([
          this.api.getScripts(p),
          this.api.getChains(p).catch(() => []),
          this.api.getCategories(p).catch(() => []),
        ]);
        this.scripts.set(scripts);
        this.chains.set(chains);
        this.categoryOrder.set(cats);
      } catch {
        this.toast.show("Skripte konnten nicht geladen werden");
      }
    }
    this.loaded.set(true);
  }

  async wake(): Promise<void> {
    const p = this.profile();
    if (!p) return;
    try {
      await this.api.wol(p.macAddress);
      this.toast.show(
        "Magic Packet gesendet ⚡ – warte, bis der PC hochfährt.",
      );
    } catch {
      this.toast.show("Wake-on-LAN fehlgeschlagen");
    }
  }

  async runScript(s: ScriptConfig): Promise<void> {
    const p = this.profile();
    if (!p) return;
    if (s.confirm && !confirm(`„${s.name}“ wirklich ausführen?`)) return;
    this.running.set(s.id);
    try {
      const res = await this.api.runScript(p, s.id);
      this.result.set(res);
    } catch {
      this.toast.show("Ausführung fehlgeschlagen");
    } finally {
      this.running.set(null);
    }
  }

  async runChain(c: ScriptChain): Promise<void> {
    const p = this.profile();
    if (!p) return;
    this.running.set(c.id);
    try {
      await this.api.runChain(p, c.id);
      this.toast.show(`Ablauf „${c.name}“ ausgeführt ✅`);
    } catch {
      this.toast.show("Ablauf fehlgeschlagen");
    } finally {
      this.running.set(null);
    }
  }

  // --- Volume ---
  async openVolume(): Promise<void> {
    const p = this.profile();
    if (!p) return;
    this.volumeOpen.set(true);
    try {
      const v = await this.api.getVolume(p);
      this.volume.set(Math.round((v?.level ?? 0) * 100));
      this.muted.set(!!v?.muted);
    } catch {
      /* ignore */
    }
  }
  async onVolume(val: number | string): Promise<void> {
    const p = this.profile();
    if (!p) return;
    const level = Number(val);
    this.volume.set(level);
    try {
      await this.api.setVolume(p, level / 100);
    } catch {
      /* ignore */
    }
  }
  async toggleMute(): Promise<void> {
    const p = this.profile();
    if (!p) return;
    const next = !this.muted();
    this.muted.set(next);
    try {
      await this.api.setMute(p, next);
    } catch {
      /* ignore */
    }
  }

  // --- Clipboard ---
  openClipboard(): void {
    this.clipText = "";
    this.clipOpen.set(true);
  }
  async pullClipboard(): Promise<void> {
    const p = this.profile();
    if (!p) return;
    this.clipText = await this.api.getClipboard(p);
  }
  async sendClipboard(): Promise<void> {
    const p = this.profile();
    if (!p) return;
    try {
      await this.api.setClipboard(p, this.clipText);
      this.toast.show("An PC gesendet 📋");
      this.clipOpen.set(false);
    } catch {
      this.toast.show("Senden fehlgeschlagen");
    }
  }
}
