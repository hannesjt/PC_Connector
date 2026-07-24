import {
  Component,
  ElementRef,
  inject,
  signal,
  viewChild,
} from "@angular/core";
import { FormsModule } from "@angular/forms";
import { Router } from "@angular/router";
import { ApiService } from "../../core/services/api.service";
import { ProfileService } from "../../core/services/profile.service";
import { PcProfile } from "../../core/models/pc-profile.model";

@Component({
  selector: "app-input-control",
  standalone: true,
  imports: [FormsModule],
  template: `
    <header class="app-bar">
      <button class="icon-btn" (click)="back()">←</button>
      <h1 class="app-bar__title">Maus &amp; Tastatur</h1>
    </header>

    <div class="page">
      <div
        #pad
        class="touchpad"
        (pointerdown)="onDown($event)"
        (pointermove)="onMove($event)"
        (pointerup)="onUp($event)"
        (pointercancel)="onUp($event)"
      >
        <span class="muted">Touchpad – hier bewegen &amp; tippen</span>
      </div>

      <div class="row" style="margin-top:12px">
        <button class="btn btn--block btn--lg" (pointerdown)="click('left')">
          Linksklick
        </button>
        <button class="btn btn--block btn--lg" (pointerdown)="click('right')">
          Rechtsklick
        </button>
      </div>

      <div class="card">
        <p class="card__title">Scrollen</p>
        <div class="row">
          <button class="btn btn--block" (pointerdown)="scroll(-3)">
            ▲ Hoch
          </button>
          <button class="btn btn--block" (pointerdown)="scroll(3)">
            ▼ Runter
          </button>
        </div>
      </div>

      <div class="card">
        <p class="card__title">Tastatur</p>
        <div class="field">
          <label>Text tippen</label>
          <div class="row">
            <input
              class="input"
              [(ngModel)]="text"
              placeholder="Text eingeben…"
              (keyup.enter)="sendText()"
            />
            <button class="btn btn--primary" (click)="sendText()">
              Senden
            </button>
          </div>
        </div>
        <div class="keys">
          @for (k of keys; track k.key) {
            <button class="btn" (click)="key(k.key)">{{ k.label }}</button>
          }
        </div>
      </div>
    </div>
  `,
  styles: [
    `
      .touchpad {
        margin-top: 16px;
        height: 46vh;
        min-height: 240px;
        border: 2px dashed var(--border);
        border-radius: var(--radius);
        background: var(--surface);
        display: flex;
        align-items: center;
        justify-content: center;
        touch-action: none;
        user-select: none;
        cursor: crosshair;
      }
      .keys {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(84px, 1fr));
        gap: 8px;
        margin-top: 8px;
      }
    `,
  ],
})
export class InputControlComponent {
  private api = inject(ApiService);
  private profiles = inject(ProfileService);
  private router = inject(Router);

  private pad = viewChild<ElementRef<HTMLDivElement>>("pad");
  readonly profile = signal<PcProfile | undefined>(undefined);

  text = "";
  private last: { x: number; y: number } | null = null;
  private moved = false;
  private downTime = 0;
  private sensitivity = 1.6;

  readonly keys = [
    { key: "enter", label: "⏎ Enter" },
    { key: "backspace", label: "⌫ Back" },
    { key: "tab", label: "⇥ Tab" },
    { key: "escape", label: "Esc" },
    { key: "up", label: "▲" },
    { key: "down", label: "▼" },
    { key: "left", label: "◀" },
    { key: "right", label: "▶" },
    { key: "win", label: "⊞ Win" },
  ];

  constructor() {
    const id = this.router.url.split("/")[2] ?? "";
    this.profile.set(this.profiles.getById(id));
  }

  back(): void {
    const p = this.profile();
    this.router.navigate(p ? ["/pc", p.id] : ["/"]);
  }

  onDown(ev: PointerEvent): void {
    this.pad()?.nativeElement.setPointerCapture(ev.pointerId);
    this.last = { x: ev.clientX, y: ev.clientY };
    this.moved = false;
    this.downTime = Date.now();
  }

  onMove(ev: PointerEvent): void {
    if (!this.last) return;
    const dx = (ev.clientX - this.last.x) * this.sensitivity;
    const dy = (ev.clientY - this.last.y) * this.sensitivity;
    this.last = { x: ev.clientX, y: ev.clientY };
    if (Math.abs(dx) > 0.5 || Math.abs(dy) > 0.5) {
      this.moved = true;
      const p = this.profile();
      if (p) this.api.mouseMove(p, dx, dy).catch(() => {});
    }
  }

  onUp(_ev: PointerEvent): void {
    // A quick tap without movement is a left click.
    if (!this.moved && Date.now() - this.downTime < 250) {
      this.click("left");
    }
    this.last = null;
  }

  click(button: "left" | "right"): void {
    const p = this.profile();
    if (p) this.api.mouseClick(p, button).catch(() => {});
  }

  scroll(dy: number): void {
    const p = this.profile();
    if (p) this.api.mouseScroll(p, 0, dy).catch(() => {});
  }

  sendText(): void {
    const p = this.profile();
    if (p && this.text) {
      this.api.keyboardType(p, this.text).catch(() => {});
      this.text = "";
    }
  }

  key(k: string): void {
    const p = this.profile();
    if (p) this.api.keyboardKey(p, k).catch(() => {});
  }
}
