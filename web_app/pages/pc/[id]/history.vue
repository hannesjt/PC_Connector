<template>
  <div>
    <header class="app-bar">
      <button class="icon-btn" @click="back">←</button>
      <h1 class="app-bar__title">Skript-Verlauf</h1>
      <button class="icon-btn" title="Aktualisieren" @click="load">🔄</button>
      <button class="icon-btn" title="Leeren" @click="clear">🗑️</button>
    </header>

    <div class="page">
      <div v-if="loading" class="empty"><span class="spin">🔄</span> Lädt…</div>
      <div v-else-if="entries.length === 0" class="empty">
        Noch keine Ausführungen.
      </div>

      <div
        v-for="(e, i) in entries"
        :key="i"
        class="card"
        style="display: flex; align-items: center; gap: 12px; margin-top: 10px"
      >
        <span style="font-size: 1.3rem">{{ e.success ? "✅" : "❌" }}</span>
        <div style="flex: 1; min-width: 0">
          <div style="font-weight: 600">{{ e.script_name }}</div>
          <div class="muted" style="font-size: 0.78rem">
            {{ format(e.timestamp) }} · Exit {{ e.exit_code }}
          </div>
          <div
            v-if="e.stderr"
            style="color: var(--danger); font-size: 0.78rem; margin-top: 4px"
          >
            {{ e.stderr }}
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { HistoryEntry, PcProfile } from "~/types/models";

const api = useApi();
const profiles = useProfiles();
const router = useRouter();
const route = useRoute();
const toast = useToast();

const profile = ref<PcProfile | undefined>(undefined);
const entries = ref<HistoryEntry[]>([]);
const loading = ref(false);

onMounted(() => {
  profiles.load();
  profile.value = profiles.getById(route.params.id as string);
  if (profile.value) load();
});

async function load(): Promise<void> {
  const p = profile.value;
  if (!p) return;
  loading.value = true;
  try {
    entries.value = (await api.getHistory(p)) as HistoryEntry[];
  } finally {
    loading.value = false;
  }
}

async function clear(): Promise<void> {
  const p = profile.value;
  if (!p || !confirm("Gesamten Verlauf löschen?")) return;
  try {
    await api.clearHistory(p);
    entries.value = [];
    toast.show("Verlauf geleert");
  } catch {
    toast.show("Fehlgeschlagen");
  }
}

function format(ts: number): string {
  return new Date(ts * 1000).toLocaleString("de-DE");
}

function back(): void {
  router.push(profile.value ? `/pc/${profile.value.id}` : "/");
}
</script>
