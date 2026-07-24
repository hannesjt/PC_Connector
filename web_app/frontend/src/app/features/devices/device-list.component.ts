import { Component, inject, signal } from "@angular/core";
import { Router } from "@angular/router";
import { ProfileService } from "../../core/services/profile.service";
import { ApiService } from "../../core/services/api.service";
import { ThemeService } from "../../core/services/theme.service";
import { ToastService } from "../../core/services/toast.service";
import { PcProfile } from "../../core/models/pc-profile.model";

@Component({
  selector: "app-device-list",
  standalone: true,
  template: `
    <header class="app-bar">
      <h1 class="app-bar__title">PC Connector</h1>
      <button class="icon-btn" title="Aktualisieren" (click)="refreshAll()">
        🔄
      </button>
      <button class="icon-btn" title="Design wechseln" (click)="theme.toggle()">
        {{ theme.dark() ? "☀️" : "🌙" }}
      </button>
    </header>

    <div class="page">
      @if (profiles.profiles().length === 0) {
        <div class="empty">
          <div style="font-size:3rem">🖥️</div>
          <p>
            Noch kein PC hinzugefügt.<br />Füge deinen PC hinzu, um ihn zu
            steuern.
          </p>
        </div>
      }

      @for (p of profiles.profiles(); track p.id) {
        <div
          class="card"
          style="display:flex;align-items:center;gap:14px;cursor:pointer"
          (click)="open(p)"
        >
          <span
            class="dot"
            [class.dot--online]="online()[p.id] === true"
            [class.dot--offline]="online()[p.id] === false"
          ></span>
          <div style="flex:1;min-width:0">
            <div style="font-weight:650;font-size:1.05rem">{{ p.name }}</div>
            <div class="muted" style="font-size:0.82rem">
              {{ p.ipAddress }}:{{ p.port }}
              @if (online()[p.id] === true) {
                · online
              } @else if (online()[p.id] === false) {
                · offline
              } @else {
                · …
              }
            </div>
          </div>
          <button
            class="icon-btn"
            title="Aufwecken (Wake-on-LAN)"
            (click)="wake(p, $event)"
          >
            ⚡
          </button>
          <button
            class="icon-btn"
            title="Entfernen"
            (click)="remove(p, $event)"
          >
            🗑️
          </button>
        </div>
      }

      <div class="card">
        <p class="card__title">Im Netzwerk suchen</p>
        <button
          class="btn btn--block"
          (click)="discover()"
          [disabled]="scanning()"
        >
          @if (scanning()) {
            <span class="spin">🔄</span> Suche läuft…
          } @else {
            📡 PCs im Netzwerk suchen
          }
        </button>
        @for (a of found(); track a.mac) {
          <div class="row" style="margin-top:12px">
            <div style="flex:1">
              <div style="font-weight:600">{{ a.name }}</div>
              <div class="muted" style="font-size:0.8rem">
                {{ a.ip }}:{{ a.port }}
              </div>
            </div>
            <button class="btn btn--primary" (click)="addDiscovered(a)">
              Hinzufügen
            </button>
          </div>
        }
      </div>
    </div>

    <button class="fab" (click)="router.navigate(['/setup'])">
      ＋ PC hinzufügen
    </button>
  `,
})
export class DeviceListComponent {
  protected profiles = inject(ProfileService);
  protected theme = inject(ThemeService);
  protected router = inject(Router);
  private api = inject(ApiService);
  private toast = inject(ToastService);

  readonly online = signal<Record<string, boolean | undefined>>({});
  readonly scanning = signal(false);
  readonly found = signal<
    { name: string; ip: string; port: number; mac: string }[]
  >([]);

  constructor() {
    this.refreshAll();
  }

  refreshAll(): void {
    for (const p of this.profiles.profiles()) {
      this.api
        .isOnline(p)
        .then((ok) => this.online.update((m) => ({ ...m, [p.id]: ok })));
    }
  }

  open(p: PcProfile): void {
    this.router.navigate(["/pc", p.id]);
  }

  async wake(p: PcProfile, ev: Event): Promise<void> {
    ev.stopPropagation();
    try {
      await this.api.wol(p.macAddress);
      this.toast.show(`Magic Packet an ${p.name} gesendet ⚡`);
    } catch {
      this.toast.show("Wake-on-LAN fehlgeschlagen");
    }
  }

  remove(p: PcProfile, ev: Event): void {
    ev.stopPropagation();
    if (confirm(`"${p.name}" wirklich entfernen?`)) {
      this.profiles.remove(p.id);
    }
  }

  async discover(): Promise<void> {
    this.scanning.set(true);
    this.found.set([]);
    try {
      const agents = await this.api.discover();
      const known = new Set(
        this.profiles.profiles().map((p) => p.macAddress.toLowerCase()),
      );
      this.found.set(
        agents.filter((a) => !known.has((a.mac ?? "").toLowerCase())),
      );
      if (agents.length === 0) this.toast.show("Kein PC im Netzwerk gefunden");
    } catch {
      this.toast.show("Suche fehlgeschlagen");
    } finally {
      this.scanning.set(false);
    }
  }

  addDiscovered(a: {
    name: string;
    ip: string;
    port: number;
    mac: string;
  }): void {
    this.router.navigate(["/setup"], {
      queryParams: { name: a.name, ip: a.ip, port: a.port, mac: a.mac },
    });
  }
}
