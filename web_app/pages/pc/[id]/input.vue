<template>
  <div>
    <header class="app-bar">
      <button class="icon-btn" @click="back">←</button>
      <h1 class="app-bar__title">Maus &amp; Tastatur</h1>
    </header>

    <div class="page">
      <div
        ref="pad"
        class="touchpad"
        @pointerdown="onDown"
        @pointermove="onMove"
        @pointerup="onUp"
        @pointercancel="onUp"
      >
        <span class="muted">Touchpad – hier bewegen &amp; tippen</span>
      </div>

      <div class="row" style="margin-top: 12px">
        <button class="btn btn--block btn--lg" @pointerdown="click('left')">
          Linksklick
        </button>
        <button class="btn btn--block btn--lg" @pointerdown="click('right')">
          Rechtsklick
        </button>
      </div>

      <div class="card">
        <p class="card__title">Scrollen</p>
        <div class="row">
          <button class="btn btn--block" @pointerdown="scroll(-3)">
            ▲ Hoch
          </button>
          <button class="btn btn--block" @pointerdown="scroll(3)">
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
              v-model="text"
              class="input"
              placeholder="Text eingeben…"
              @keyup.enter="sendText"
            />
            <button class="btn btn--primary" @click="sendText">Senden</button>
          </div>
        </div>
        <div class="keys">
          <button
            v-for="k in keys"
            :key="k.key"
            class="btn"
            @click="key(k.key)"
          >
            {{ k.label }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { PcProfile } from "~/types/models";

const api = useApi();
const profiles = useProfiles();
const router = useRouter();
const route = useRoute();

const pad = ref<HTMLDivElement | null>(null);
const profile = ref<PcProfile | undefined>(undefined);
const text = ref("");

let last: { x: number; y: number } | null = null;
let moved = false;
let downTime = 0;
const sensitivity = 1.6;

const keys = [
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

onMounted(() => {
  profiles.load();
  profile.value = profiles.getById(route.params.id as string);
});

function back(): void {
  router.push(profile.value ? `/pc/${profile.value.id}` : "/");
}

function onDown(ev: PointerEvent): void {
  pad.value?.setPointerCapture(ev.pointerId);
  last = { x: ev.clientX, y: ev.clientY };
  moved = false;
  downTime = Date.now();
}

function onMove(ev: PointerEvent): void {
  if (!last) return;
  const dx = (ev.clientX - last.x) * sensitivity;
  const dy = (ev.clientY - last.y) * sensitivity;
  last = { x: ev.clientX, y: ev.clientY };
  if (Math.abs(dx) > 0.5 || Math.abs(dy) > 0.5) {
    moved = true;
    const p = profile.value;
    if (p) api.mouseMove(p, dx, dy).catch(() => {});
  }
}

function onUp(): void {
  if (!moved && Date.now() - downTime < 250) {
    click("left");
  }
  last = null;
}

function click(button: "left" | "right"): void {
  const p = profile.value;
  if (p) api.mouseClick(p, button).catch(() => {});
}

function scroll(dy: number): void {
  const p = profile.value;
  if (p) api.mouseScroll(p, 0, dy).catch(() => {});
}

function sendText(): void {
  const p = profile.value;
  if (p && text.value) {
    api.keyboardType(p, text.value).catch(() => {});
    text.value = "";
  }
}

function key(k: string): void {
  const p = profile.value;
  if (p) api.keyboardKey(p, k).catch(() => {});
}
</script>
