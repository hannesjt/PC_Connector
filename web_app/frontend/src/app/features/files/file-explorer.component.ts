import { Component, inject, signal } from "@angular/core";
import { Router } from "@angular/router";
import { ApiService } from "../../core/services/api.service";
import { ProfileService } from "../../core/services/profile.service";
import { ToastService } from "../../core/services/toast.service";
import { PcProfile } from "../../core/models/pc-profile.model";
import { FileEntry } from "../../core/models/script.model";

@Component({
  selector: "app-file-explorer",
  standalone: true,
  template: `
    <header class="app-bar">
      <button class="icon-btn" (click)="back()">←</button>
      <div style="flex:1;min-width:0">
        <h1 class="app-bar__title">Dateien</h1>
        <div class="app-bar__sub">{{ path() || "Laufwerke / Home" }}</div>
      </div>
      <button
        class="icon-btn"
        title="Hochladen"
        (click)="fileInput.click()"
        [disabled]="!path()"
      >
        ⬆️
      </button>
      <button class="icon-btn" title="Aktualisieren" (click)="load(path())">
        🔄
      </button>
    </header>
    <input #fileInput type="file" hidden (change)="upload($event)" />

    <div class="page">
      @if (path()) {
        <button
          class="btn btn--block"
          style="justify-content:flex-start;margin-top:16px"
          (click)="goUp()"
        >
          ⬅️ Übergeordneter Ordner
        </button>
      }

      @if (loading()) {
        <div class="empty"><span class="spin">🔄</span> Lädt…</div>
      } @else if (entries().length === 0) {
        <div class="empty">Leer oder kein Zugriff.</div>
      }

      @for (e of entries(); track e.path) {
        <div class="card entry" (click)="onEntry(e)">
          <span style="font-size:1.4rem">{{ e.is_dir ? "📁" : "📄" }}</span>
          <div style="flex:1;min-width:0">
            <div
              style="overflow:hidden;text-overflow:ellipsis;white-space:nowrap"
            >
              {{ e.name }}
            </div>
            @if (!e.is_dir) {
              <div class="muted" style="font-size:0.78rem">
                {{ size(e.size) }}
              </div>
            }
          </div>
          @if (!e.is_dir) {
            <a
              class="icon-btn"
              title="Herunterladen"
              [href]="downloadUrl(e)"
              (click)="$event.stopPropagation()"
              download
              >⬇️</a
            >
            <button
              class="icon-btn"
              title="Auf PC öffnen"
              (click)="openOnPc(e, $event)"
            >
              ↗️
            </button>
          }
        </div>
      }
    </div>
  `,
  styles: [
    `
      .entry {
        display: flex;
        align-items: center;
        gap: 12px;
        margin-top: 10px;
        padding: 12px 14px;
        cursor: pointer;
      }
    `,
  ],
})
export class FileExplorerComponent {
  private api = inject(ApiService);
  private profiles = inject(ProfileService);
  private router = inject(Router);
  private toast = inject(ToastService);

  readonly profile = signal<PcProfile | undefined>(undefined);
  readonly path = signal("");
  readonly entries = signal<FileEntry[]>([]);
  readonly loading = signal(false);

  constructor() {
    const id = this.router.url.split("/")[2] ?? "";
    this.profile.set(this.profiles.getById(id));
    if (this.profile()) this.load("");
  }

  back(): void {
    const p = this.profile();
    this.router.navigate(p ? ["/pc", p.id] : ["/"]);
  }

  async load(path: string): Promise<void> {
    const p = this.profile();
    if (!p) return;
    this.loading.set(true);
    try {
      const list = await this.api.listFiles(p, path);
      this.path.set(path);
      this.entries.set(list);
    } catch {
      this.toast.show("Ordner konnte nicht geladen werden");
    } finally {
      this.loading.set(false);
    }
  }

  onEntry(e: FileEntry): void {
    if (e.is_dir) this.load(e.path);
  }

  goUp(): void {
    const cur = this.path();
    const sep = cur.includes("\\") ? "\\" : "/";
    const trimmed = cur.replace(/[\\/]+$/, "");
    const idx = trimmed.lastIndexOf(sep);
    if (idx <= 2) {
      // Back to drive/home overview.
      this.load("");
    } else {
      this.load(trimmed.slice(0, idx + 1));
    }
  }

  downloadUrl(e: FileEntry): string {
    const p = this.profile();
    return p ? this.api.fileDownloadUrl(p, e.path) : "#";
  }

  async openOnPc(e: FileEntry, ev: Event): Promise<void> {
    ev.stopPropagation();
    const p = this.profile();
    if (!p) return;
    try {
      await this.api.openFileOnPc(p, e.path);
      this.toast.show("Auf dem PC geöffnet ↗️");
    } catch {
      this.toast.show("Öffnen fehlgeschlagen");
    }
  }

  async upload(ev: Event): Promise<void> {
    const input = ev.target as HTMLInputElement;
    const file = input.files?.[0];
    const p = this.profile();
    if (!file || !p || !this.path()) return;
    this.toast.show("Lade hoch…");
    try {
      await this.api.uploadFile(p, this.path(), file);
      this.toast.show("Hochgeladen ✅");
      this.load(this.path());
    } catch {
      this.toast.show("Upload fehlgeschlagen");
    } finally {
      input.value = "";
    }
  }

  size(bytes: number): string {
    if (bytes < 1024) return `${bytes} B`;
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
    if (bytes < 1024 * 1024 * 1024)
      return `${(bytes / 1024 / 1024).toFixed(1)} MB`;
    return `${(bytes / 1024 / 1024 / 1024).toFixed(1)} GB`;
  }
}
