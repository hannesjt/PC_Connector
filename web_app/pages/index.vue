<template>
  <div>
    <header class="app-bar">
      <h1 class="app-bar__title">PC Connector</h1>
      <button class="icon-btn" title="Aktualisieren" @click="refreshAll">
        🔄
      </button>
      <button class="icon-btn" title="Design wechseln" @click="theme.toggle()">
        {{ theme.dark.value ? "☀️" : "🌙" }}
      </button>
    </header>

    <div class="page">
      <div v-if="profiles.profiles.value.length === 0" class="empty">
        <div style="font-size: 3rem">🖥️</div>
        <p>
          Noch kein PC hinzugefügt.<br />Füge deinen PC hinzu, um ihn zu
          steuern.
        </p>
      </div>

      <div
        v-for="p in profiles.profiles.value"
        :key="p.id"
        class="card"
        style="display: flex; align-items: center; gap: 14px; cursor: pointer"
        @click="open(p)"
      >
        <span
          class="dot"
          :class="{
            'dot--online': online[p.id] === true,
            'dot--offline': online[p.id] === false,
          }"
        ></span>
        <div style="flex: 1; min-width: 0">
          <div style="font-weight: 650; font-size: 1.05rem">{{ p.name }}</div>
          <div class="muted" style="font-size: 0.82rem">
            {{ p.ipAddress }}:{{ p.port }}
            <template v-if="online[p.id] === true"> · online</template>
            <template v-else-if="online[p.id] === false"> · offline</template>
            <template v-else> · …</template>
          </div>
        </div>
        <button
          class="icon-btn"
          title="Aufwecken (Wake-on-LAN)"
          @click="wake(p, $event)"
        >
          ⚡
        </button>
        <button class="icon-btn" title="Entfernen" @click="remove(p, $event)">
          🗑️
        </button>
      </div>

      <div class="card">
        <p class="card__title">Im Netzwerk suchen</p>
        <button class="btn btn--block" :disabled="scanning" @click="discover">
          <template v-if="scanning"
            ><span class="spin">🔄</span> Suche läuft…</template
          >
          <template v-else>📡 PCs im Netzwerk suchen</template>
        </button>
        <div
          v-for="a in found"
          :key="a.mac"
          class="row"
          style="margin-top: 12px"
        >
          <div style="flex: 1">
            <div style="font-weight: 600">{{ a.name }}</div>
            <div class="muted" style="font-size: 0.8rem">
              {{ a.ip }}:{{ a.port }}
            </div>
          </div>
          <button class="btn btn--primary" @click="addDiscovered(a)">
            Hinzufügen
          </button>
        </div>
      </div>
    </div>

    <button class="fab" @click="router.push('/setup')">＋ PC hinzufügen</button>
  </div>
</template>

<script setup lang="ts">
import type { DiscoveredAgent, PcProfile } from "~/types/models";

const profiles = useProfiles();
const theme = useTheme();
const api = useApi();
const toast = useToast();
const router = useRouter();

const online = reactive<Record<string, boolean | undefined>>({});
const scanning = ref(false);
const found = ref<DiscoveredAgent[]>([]);

onMounted(() => {
  profiles.load();
  refreshAll();
});

function refreshAll(): void {
  for (const p of profiles.profiles.value) {
    api.isOnline(p).then((ok) => (online[p.id] = ok));
  }
}

function open(p: PcProfile): void {
  router.push(`/pc/${p.id}`);
}

async function wake(p: PcProfile, ev: Event): Promise<void> {
  ev.stopPropagation();
  try {
    await api.wol(p.macAddress);
    toast.show(`Magic Packet an ${p.name} gesendet ⚡`);
  } catch {
    toast.show("Wake-on-LAN fehlgeschlagen");
  }
}

function remove(p: PcProfile, ev: Event): void {
  ev.stopPropagation();
  if (confirm(`"${p.name}" wirklich entfernen?`)) {
    profiles.remove(p.id);
  }
}

async function discover(): Promise<void> {
  scanning.value = true;
  found.value = [];
  try {
    const agents = await api.discover();
    const known = new Set(
      profiles.profiles.value.map((p) => p.macAddress.toLowerCase()),
    );
    found.value = agents.filter((a) => !known.has((a.mac ?? "").toLowerCase()));
    if (agents.length === 0) toast.show("Kein PC im Netzwerk gefunden");
  } catch {
    toast.show("Suche fehlgeschlagen");
  } finally {
    scanning.value = false;
  }
}

function addDiscovered(a: DiscoveredAgent): void {
  router.push({
    path: "/setup",
    query: { name: a.name, ip: a.ip, port: a.port, mac: a.mac },
  });
}
</script>
