<template>
  <div>
    <header class="app-bar">
      <button class="icon-btn" @click="router.push('/')">←</button>
      <h1 class="app-bar__title">PC hinzufügen</h1>
    </header>

    <div class="page">
      <div class="card">
        <p class="card__title">Verbindung</p>
        <div class="field">
          <label>Name</label>
          <input v-model="name" class="input" placeholder="Mein PC" />
        </div>
        <div class="row" style="align-items: flex-end; gap: 12px">
          <div class="field" style="flex: 1; margin: 0">
            <label>IP-Adresse</label>
            <input
              v-model="ip"
              class="input"
              placeholder="192.168.1.50"
              inputmode="decimal"
            />
          </div>
          <div class="field" style="width: 96px; margin: 0">
            <label>Port</label>
            <input v-model.number="port" class="input" inputmode="numeric" />
          </div>
        </div>
      </div>

      <div class="card">
        <p class="card__title">Kopplung</p>
        <p class="muted" style="margin-top: 0; font-size: 0.88rem">
          Öffne die Weboberfläche des PC-Agents (z.&nbsp;B.
          <code>http://{{ ip || "PC-IP" }}:{{ port }}</code
          >) und klicke auf „Code generieren“. Gib den Code hier ein.
        </p>
        <div class="field">
          <label>Kopplungscode</label>
          <input
            v-model="code"
            class="input"
            placeholder="123456"
            inputmode="numeric"
            style="letter-spacing: 0.3em; font-size: 1.2rem; text-align: center"
          />
        </div>
        <button
          class="btn btn--primary btn--block btn--lg"
          :disabled="busy"
          @click="pair"
        >
          <template v-if="busy"
            ><span class="spin">🔄</span> Verbinde…</template
          >
          <template v-else>🔗 Verbinden</template>
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
const router = useRouter();
const route = useRoute();
const api = useApi();
const profiles = useProfiles();
const toast = useToast();

const name = ref((route.query.name as string) ?? "");
const ip = ref((route.query.ip as string) ?? "");
const port = ref(route.query.port ? Number(route.query.port) : 8420);
const code = ref("");
const mac = ref((route.query.mac as string) ?? "");
const busy = ref(false);

onMounted(() => profiles.load());

async function pair(): Promise<void> {
  if (!ip.value.trim() || !code.value.trim()) {
    toast.show("Bitte IP-Adresse und Code eingeben");
    return;
  }
  busy.value = true;
  try {
    const base = `http://${ip.value.trim()}:${port.value}`;
    const res = await api.pair(
      base,
      code.value.trim(),
      name.value.trim() || "Web-Browser",
    );
    if (!res.success || !res.token) {
      toast.show(res.message || "Kopplung fehlgeschlagen");
      return;
    }
    const id = profiles.newId();
    profiles.add({
      id,
      name: name.value.trim() || res.pc_name || "Mein PC",
      ipAddress: ip.value.trim(),
      port: port.value,
      macAddress: res.mac_address || mac.value,
      deviceToken: res.token,
      lastSeen: Date.now(),
    });
    toast.show("Verbunden ✅");
    router.push(`/pc/${id}`);
  } catch {
    toast.show("PC nicht erreichbar. IP/Port prüfen.");
  } finally {
    busy.value = false;
  }
}
</script>
