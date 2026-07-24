import { Component, inject, signal } from "@angular/core";
import { FormsModule } from "@angular/forms";
import { ActivatedRoute, Router } from "@angular/router";
import { ApiService } from "../../core/services/api.service";
import { ProfileService } from "../../core/services/profile.service";
import { ToastService } from "../../core/services/toast.service";

@Component({
  selector: "app-setup",
  standalone: true,
  imports: [FormsModule],
  template: `
    <header class="app-bar">
      <button class="icon-btn" (click)="router.navigate(['/'])">←</button>
      <h1 class="app-bar__title">PC hinzufügen</h1>
    </header>

    <div class="page">
      <div class="card">
        <p class="card__title">Verbindung</p>
        <div class="field">
          <label>Name</label>
          <input class="input" [(ngModel)]="name" placeholder="Mein PC" />
        </div>
        <div class="row" style="align-items:flex-end;gap:12px">
          <div class="field" style="flex:1;margin:0">
            <label>IP-Adresse</label>
            <input
              class="input"
              [(ngModel)]="ip"
              placeholder="192.168.1.50"
              inputmode="decimal"
            />
          </div>
          <div class="field" style="width:96px;margin:0">
            <label>Port</label>
            <input class="input" [(ngModel)]="port" inputmode="numeric" />
          </div>
        </div>
      </div>

      <div class="card">
        <p class="card__title">Kopplung</p>
        <p class="muted" style="margin-top:0;font-size:0.88rem">
          Öffne die Weboberfläche des PC-Agents (z.&nbsp;B.
          <code>http://{{ ip || "PC-IP" }}:{{ port }}</code
          >) und klicke auf „Code generieren“. Gib den Code hier ein.
        </p>
        <div class="field">
          <label>Kopplungscode</label>
          <input
            class="input"
            [(ngModel)]="code"
            placeholder="123456"
            inputmode="numeric"
            style="letter-spacing:0.3em;font-size:1.2rem;text-align:center"
          />
        </div>
        <button
          class="btn btn--primary btn--block btn--lg"
          (click)="pair()"
          [disabled]="busy()"
        >
          @if (busy()) {
            <span class="spin">🔄</span> Verbinde…
          } @else {
            🔗 Verbinden
          }
        </button>
      </div>
    </div>
  `,
})
export class SetupComponent {
  protected router = inject(Router);
  private route = inject(ActivatedRoute);
  private api = inject(ApiService);
  private profiles = inject(ProfileService);
  private toast = inject(ToastService);

  name = "";
  ip = "";
  port = 8420;
  code = "";
  mac = "";
  readonly busy = signal(false);

  constructor() {
    const q = this.route.snapshot.queryParamMap;
    this.name = q.get("name") ?? "";
    this.ip = q.get("ip") ?? "";
    this.port = q.get("port") ? Number(q.get("port")) : 8420;
    this.mac = q.get("mac") ?? "";
  }

  async pair(): Promise<void> {
    if (!this.ip.trim() || !this.code.trim()) {
      this.toast.show("Bitte IP-Adresse und Code eingeben");
      return;
    }
    this.busy.set(true);
    try {
      const base = `http://${this.ip.trim()}:${this.port}`;
      const res = await this.api.pair(
        base,
        this.code.trim(),
        this.name.trim() || "Web-Browser",
      );
      if (!res.success || !res.token) {
        this.toast.show(res.message || "Kopplung fehlgeschlagen");
        return;
      }
      const id = this.profiles.newId();
      this.profiles.add({
        id,
        name: this.name.trim() || res.pc_name || "Mein PC",
        ipAddress: this.ip.trim(),
        port: this.port,
        macAddress: res.mac_address || this.mac,
        deviceToken: res.token,
        lastSeen: Date.now(),
      });
      this.toast.show("Verbunden ✅");
      this.router.navigate(["/pc", id]);
    } catch {
      this.toast.show("PC nicht erreichbar. IP/Port prüfen.");
    } finally {
      this.busy.set(false);
    }
  }
}
