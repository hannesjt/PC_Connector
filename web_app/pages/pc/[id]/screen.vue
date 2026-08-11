<template>
  <div>
    <header class="app-bar">
      <button class="icon-btn" @click="back">←</button>
      <h1 class="app-bar__title">Bildschirm</h1>
      <button class="icon-btn" :title="live ? 'Pause' : 'Live'" @click="toggle">
        {{ live ? "⏸️" : "▶️" }}
      </button>
    </header>

    <div class="page">
      <div class="screen-wrap">
        <img
          v-if="src"
          class="screen-img"
          :src="src"
          alt="PC-Bildschirm"
          @error="onError"
        />
        <div v-else class="empty">Kein Bild.</div>
      </div>

      <div class="card">
        <p class="card__title">Aktualisierungsrate</p>
        <div class="row">
          <button
            class="btn btn--block"
            :class="{ 'btn--primary': interval === 2000 }"
            @click="setRate(2000)"
          >
            Langsam
          </button>
          <button
            class="btn btn--block"
            :class="{ 'btn--primary': interval === 1000 }"
            @click="setRate(1000)"
          >
            Normal
          </button>
          <button
            class="btn btn--block"
            :class="{ 'btn--primary': interval === 400 }"
            @click="setRate(400)"
          >
            Schnell
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

const profile = ref<PcProfile | undefined>(undefined);
const src = ref("");
const live = ref(true);
const interval = ref(1000);
let timer: ReturnType<typeof setInterval> | null = null;

onMounted(() => {
  profiles.load();
  profile.value = profiles.getById(route.params.id as string);
  start();
});

onBeforeUnmount(() => stop());

function tick(): void {
  const p = profile.value;
  if (p) src.value = api.screenshotUrl(p, 55, 0.6);
}

function start(): void {
  stop();
  tick();
  timer = setInterval(tick, interval.value);
}

function stop(): void {
  if (timer) {
    clearInterval(timer);
    timer = null;
  }
}

function toggle(): void {
  live.value = !live.value;
  if (live.value) start();
  else stop();
}

function setRate(ms: number): void {
  interval.value = ms;
  if (live.value) start();
}

function onError(): void {}

function back(): void {
  router.push(profile.value ? `/pc/${profile.value.id}` : "/");
}
</script>
