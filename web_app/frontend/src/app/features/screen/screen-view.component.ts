import { Component, OnDestroy, inject, signal } from "@angular/core";
import { Router } from "@angular/router";
import { ApiService } from "../../core/services/api.service";
import { ProfileService } from "../../core/services/profile.service";
import { PcProfile } from "../../core/models/pc-profile.model";

@Component({
  selector: "app-screen-view",
  standalone: true,
  template: `
    <header class="app-bar">
      <button class="icon-btn" (click)="back()">←</button>
      <h1 class="app-bar__title">Bildschirm</h1>
      <button
        class="icon-btn"
        [title]="live() ? 'Pause' : 'Live'"
        (click)="toggle()"
      >
        {{ live() ? "⏸️" : "▶️" }}
      </button>
    </header>

    <div class="page">
      <div class="screen-wrap">
        @if (src()) {
          <img
            class="screen-img"
            [src]="src()"
            alt="PC-Bildschirm"
            (error)="onError()"
          />
        } @else {
          <div class="empty">Kein Bild.</div>
        }
      </div>

      <div class="card">
        <p class="card__title">Aktualisierungsrate</p>
        <div class="row">
          <button
            class="btn btn--block"
            [class.btn--primary]="interval() === 2000"
            (click)="setRate(2000)"
          >
            Langsam
          </button>
          <button
            class="btn btn--block"
            [class.btn--primary]="interval() === 1000"
            (click)="setRate(1000)"
          >
            Normal
          </button>
          <button
            class="btn btn--block"
            [class.btn--primary]="interval() === 400"
            (click)="setRate(400)"
          >
            Schnell
          </button>
        </div>
      </div>
    </div>
  `,
  styles: [
    `
      .screen-wrap {
        margin-top: 16px;
        background: #000;
        border-radius: var(--radius);
        overflow: hidden;
        min-height: 200px;
        display: flex;
        align-items: center;
        justify-content: center;
      }
      .screen-img {
        width: 100%;
        display: block;
      }
    `,
  ],
})
export class ScreenViewComponent implements OnDestroy {
  private api = inject(ApiService);
  private profiles = inject(ProfileService);
  private router = inject(Router);

  readonly profile = signal<PcProfile | undefined>(undefined);
  readonly src = signal<string>("");
  readonly live = signal(true);
  readonly interval = signal(1000);
  private timer: ReturnType<typeof setInterval> | null = null;

  constructor() {
    const id = this.router.url.split("/")[2] ?? "";
    this.profile.set(this.profiles.getById(id));
    this.start();
  }

  private tick(): void {
    const p = this.profile();
    if (p) this.src.set(this.api.screenshotUrl(p, 55, 0.6));
  }

  private start(): void {
    this.stop();
    this.tick();
    this.timer = setInterval(() => this.tick(), this.interval());
  }

  private stop(): void {
    if (this.timer) {
      clearInterval(this.timer);
      this.timer = null;
    }
  }

  toggle(): void {
    this.live.set(!this.live());
    if (this.live()) this.start();
    else this.stop();
  }

  setRate(ms: number): void {
    this.interval.set(ms);
    if (this.live()) this.start();
  }

  onError(): void {
    // Keep the last frame; a transient failure shouldn't blank the view.
  }

  back(): void {
    const p = this.profile();
    this.router.navigate(p ? ["/pc", p.id] : ["/"]);
  }

  ngOnDestroy(): void {
    this.stop();
  }
}
