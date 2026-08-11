<template>
  <div>
    <template v-if="profile">
      <header class="app-bar">
        <button class="icon-btn" @click="router.push('/')">←</button>
        <div style="flex: 1; min-width: 0">
          <h1
            class="app-bar__title"
            style="display: flex; align-items: center; gap: 8px"
          >
            <span
              class="dot"
              :class="{
                'dot--online': online === true,
                'dot--offline': online === false,
              }"
            ></span>
            {{ profile.name }}
          </h1>
          <div class="app-bar__sub">
            {{ profile.ipAddress }}:{{ profile.port }} ·
            {{
              online === true ? "online" : online === false ? "offline" : "…"
            }}
          </div>
        </div>
        <button class="icon-btn" title="Aktualisieren" @click="refresh">
          🔄
        </button>
        <button class="icon-btn" title="Design" @click="theme.toggle()">
          {{ theme.dark.value ? "☀️" : "🌙" }}
        </button>
      </header>

      <div class="page">
        <div v-if="online === false" class="card" style="text-align: center">
          <div style="font-size: 2.2rem">😴</div>
          <p class="muted" style="margin: 8px 0 16px">
            PC ist offline oder im Ruhezustand.
          </p>
          <button class="btn btn--primary btn--lg" @click="wake">
            ⚡ Aufwecken (Wake-on-LAN)
          </button>
        </div>

        <div class="card">
          <p class="card__title">Steuerung</p>
          <div class="quick-grid">
            <div class="tile" @click="go('input')">
              <span class="tile__icon">🖱️</span
              ><span class="tile__label">Maus &amp; Tastatur</span>
            </div>
            <div class="tile" @click="openVolume">
              <span class="tile__icon">🔊</span
              ><span class="tile__label">Lautstärke</span>
            </div>
            <div class="tile" @click="openClipboard">
              <span class="tile__icon">📋</span
              ><span class="tile__label">Zwischenablage</span>
            </div>
            <div class="tile" @click="go('screen')">
              <span class="tile__icon">🖥️</span
              ><span class="tile__label">Bildschirm</span>
            </div>
            <div class="tile" @click="go('files')">
              <span class="tile__icon">📁</span
              ><span class="tile__label">Dateien</span>
            </div>
            <div class="tile" @click="go('history')">
              <span class="tile__icon">📜</span
              ><span class="tile__label">Verlauf</span>
            </div>
          </div>
        </div>

        <div v-for="g in groups" :key="g.name" class="card">
          <p class="card__title">{{ g.name || "Skripte" }}</p>
          <div class="grid">
            <button
              v-for="s in g.scripts"
              :key="s.id"
              class="tile"
              :disabled="running === s.id"
              @click="runScript(s)"
            >
              <span class="tile__icon">
                <span v-if="running === s.id" class="spin">🔄</span>
                <template v-else>{{ iconFor(s.icon) }}</template>
              </span>
              <span class="tile__label">{{ s.name }}</span>
            </button>
          </div>
        </div>

        <div v-if="chains.length" class="card">
          <p class="card__title">Abläufe</p>
          <button
            v-for="c in chains"
            :key="c.id"
            class="btn btn--block"
            style="justify-content: flex-start; margin-bottom: 8px"
            :disabled="running === c.id"
            @click="runChain(c)"
          >
            <span v-if="running === c.id" class="spin">🔄</span>
            <template v-else>🔗</template>
            {{ c.name }}
            <span class="muted" style="margin-left: auto; font-size: 0.8rem">
              {{ c.steps.length }} Schritte
            </span>
          </button>
        </div>

        <div
          v-if="loaded && groups.length === 0 && chains.length === 0"
          class="empty"
        >
          Keine Skripte konfiguriert.
        </div>
      </div>

      <div v-if="result" class="modal-backdrop" @click="result = null">
        <div class="modal" @click.stop>
          <h2 class="modal__title">
            {{ result.success ? "✅ Erfolgreich" : "❌ Fehlgeschlagen" }}
          </h2>
          <template v-if="result.stdout">
            <p class="muted" style="margin: 0 0 4px">Ausgabe</p>
            <pre class="result-pre">{{ result.stdout }}</pre>
          </template>
          <template v-if="result.stderr">
            <p class="muted" style="margin: 12px 0 4px">Fehler</p>
            <pre class="result-pre" style="color: var(--danger)">{{
              result.stderr
            }}</pre>
          </template>
          <p v-if="!result.stdout && !result.stderr" class="muted">
            Keine Ausgabe (Exit-Code {{ result.exitCode }}).
          </p>
          <button
            class="btn btn--primary btn--block"
            style="margin-top: 16px"
            @click="result = null"
          >
            Schließen
          </button>
        </div>
      </div>

      <div v-if="volumeOpen" class="modal-backdrop" @click="volumeOpen = false">
        <div class="modal" @click.stop>
          <h2 class="modal__title">🔊 Lautstärke</h2>
          <div class="row">
            <button class="icon-btn" @click="toggleMute">
              {{ muted ? "🔇" : "🔊" }}
            </button>
            <input
              type="range"
              min="0"
              max="100"
              style="flex: 1"
              :value="volume"
              @input="onVolume(($event.target as HTMLInputElement).value)"
            />
            <span style="width: 44px; text-align: right">{{ volume }}%</span>
          </div>
          <button
            class="btn btn--block"
            style="margin-top: 16px"
            @click="volumeOpen = false"
          >
            Schließen
          </button>
        </div>
      </div>

      <div v-if="clipOpen" class="modal-backdrop" @click="clipOpen = false">
        <div class="modal" @click.stop>
          <h2 class="modal__title">📋 Zwischenablage senden</h2>
          <textarea
            v-model="clipText"
            class="input"
            placeholder="Text an den PC senden…"
          ></textarea>
          <div class="row" style="margin-top: 14px; justify-content: flex-end">
            <button class="btn" @click="pullClipboard">Vom PC holen</button>
            <button class="btn btn--primary" @click="sendClipboard">
              Senden
            </button>
          </div>
        </div>
      </div>
    </template>
    <div v-else class="empty">PC nicht gefunden.</div>
  </div>
</template>

<script setup lang="ts">
import type {
  PcProfile,
  ScriptChain,
  ScriptConfig,
  ScriptResult,
} from "~/types/models";

interface Group {
  name: string;
  scripts: ScriptConfig[];
}

const router = useRouter();
const route = useRoute();
const theme = useTheme();
const api = useApi();
const profiles = useProfiles();
const toast = useToast();

const profile = ref<PcProfile | undefined>(undefined);
const online = ref<boolean | undefined>(undefined);
const scripts = ref<ScriptConfig[]>([]);
const chains = ref<ScriptChain[]>([]);
const categoryOrder = ref<string[]>([]);
const loaded = ref(false);
const running = ref<string | null>(null);
const result = ref<ScriptResult | null>(null);

const volumeOpen = ref(false);
const volume = ref(0);
const muted = ref(false);
const clipOpen = ref(false);
const clipText = ref("");

const groups = computed<Group[]>(() => {
  const byGroup = new Map<string, ScriptConfig[]>();
  for (const s of [...scripts.value].sort((a, b) => a.order - b.order)) {
    const list = byGroup.get(s.group) ?? [];
    list.push(s);
    byGroup.set(s.group, list);
  }
  const order = categoryOrder.value;
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

onMounted(() => {
  profiles.load();
  profile.value = profiles.getById(route.params.id as string);
  if (profile.value) refresh();
});

function go(sub: string): void {
  if (profile.value) router.push(`/pc/${profile.value.id}/${sub}`);
}

async function refresh(): Promise<void> {
  const p = profile.value;
  if (!p) return;
  online.value = await api.isOnline(p);
  if (online.value) {
    try {
      const [s, c, cats] = await Promise.all([
        api.getScripts(p),
        api.getChains(p).catch(() => []),
        api.getCategories(p).catch(() => []),
      ]);
      scripts.value = s;
      chains.value = c;
      categoryOrder.value = cats;
    } catch {
      toast.show("Skripte konnten nicht geladen werden");
    }
  }
  loaded.value = true;
}

async function wake(): Promise<void> {
  const p = profile.value;
  if (!p) return;
  try {
    await api.wol(p.macAddress);
    toast.show("Magic Packet gesendet ⚡ – warte, bis der PC hochfährt.");
  } catch {
    toast.show("Wake-on-LAN fehlgeschlagen");
  }
}

async function runScript(s: ScriptConfig): Promise<void> {
  const p = profile.value;
  if (!p) return;
  if (s.confirm && !confirm(`„${s.name}“ wirklich ausführen?`)) return;
  running.value = s.id;
  try {
    result.value = await api.runScript(p, s.id);
  } catch {
    toast.show("Ausführung fehlgeschlagen");
  } finally {
    running.value = null;
  }
}

async function runChain(c: ScriptChain): Promise<void> {
  const p = profile.value;
  if (!p) return;
  running.value = c.id;
  try {
    await api.runChain(p, c.id);
    toast.show(`Ablauf „${c.name}“ ausgeführt ✅`);
  } catch {
    toast.show("Ablauf fehlgeschlagen");
  } finally {
    running.value = null;
  }
}

async function openVolume(): Promise<void> {
  const p = profile.value;
  if (!p) return;
  volumeOpen.value = true;
  try {
    const v = await api.getVolume(p);
    volume.value = Math.round((v?.level ?? 0) * 100);
    muted.value = !!v?.muted;
  } catch {}
}
async function onVolume(val: number | string): Promise<void> {
  const p = profile.value;
  if (!p) return;
  const level = Number(val);
  volume.value = level;
  try {
    await api.setVolume(p, level / 100);
  } catch {}
}
async function toggleMute(): Promise<void> {
  const p = profile.value;
  if (!p) return;
  const next = !muted.value;
  muted.value = next;
  try {
    await api.setMute(p, next);
  } catch {}
}

function openClipboard(): void {
  clipText.value = "";
  clipOpen.value = true;
}
async function pullClipboard(): Promise<void> {
  const p = profile.value;
  if (!p) return;
  clipText.value = await api.getClipboard(p);
}
async function sendClipboard(): Promise<void> {
  const p = profile.value;
  if (!p) return;
  try {
    await api.setClipboard(p, clipText.value);
    toast.show("An PC gesendet 📋");
    clipOpen.value = false;
  } catch {
    toast.show("Senden fehlgeschlagen");
  }
}
</script>
