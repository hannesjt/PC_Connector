<template>
  <div>
    <header class="app-bar">
      <button class="icon-btn" @click="back">←</button>
      <div style="flex: 1; min-width: 0">
        <h1 class="app-bar__title">Dateien</h1>
        <div class="app-bar__sub">{{ path || "Laufwerke / Home" }}</div>
      </div>
      <button
        class="icon-btn"
        title="Hochladen"
        :disabled="!path"
        @click="fileInput?.click()"
      >
        ⬆️
      </button>
      <button class="icon-btn" title="Aktualisieren" @click="load(path)">
        🔄
      </button>
    </header>
    <input ref="fileInput" type="file" hidden @change="upload" />

    <div class="page">
      <button
        v-if="path"
        class="btn btn--block"
        style="justify-content: flex-start; margin-top: 16px"
        @click="goUp"
      >
        ⬅️ Übergeordneter Ordner
      </button>

      <div v-if="loading" class="empty"><span class="spin">🔄</span> Lädt…</div>
      <div v-else-if="entries.length === 0" class="empty">
        Leer oder kein Zugriff.
      </div>

      <div
        v-for="e in entries"
        :key="e.path"
        class="card entry"
        @click="onEntry(e)"
      >
        <span style="font-size: 1.4rem">{{ e.is_dir ? "📁" : "📄" }}</span>
        <div style="flex: 1; min-width: 0">
          <div
            style="
              overflow: hidden;
              text-overflow: ellipsis;
              white-space: nowrap;
            "
          >
            {{ e.name }}
          </div>
          <div v-if="!e.is_dir" class="muted" style="font-size: 0.78rem">
            {{ size(e.size) }}
          </div>
        </div>
        <template v-if="!e.is_dir">
          <a
            class="icon-btn"
            title="Herunterladen"
            :href="downloadUrl(e)"
            download
            @click.stop
            >⬇️</a
          >
          <button
            class="icon-btn"
            title="Auf PC öffnen"
            @click="openOnPc(e, $event)"
          >
            ↗️
          </button>
        </template>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { FileEntry, PcProfile } from "~/types/models";

const api = useApi();
const profiles = useProfiles();
const router = useRouter();
const route = useRoute();
const toast = useToast();

const fileInput = ref<HTMLInputElement | null>(null);
const profile = ref<PcProfile | undefined>(undefined);
const path = ref("");
const entries = ref<FileEntry[]>([]);
const loading = ref(false);

onMounted(() => {
  profiles.load();
  profile.value = profiles.getById(route.params.id as string);
  if (profile.value) load("");
});

function back(): void {
  router.push(profile.value ? `/pc/${profile.value.id}` : "/");
}

async function load(p: string): Promise<void> {
  const prof = profile.value;
  if (!prof) return;
  loading.value = true;
  try {
    const list = await api.listFiles(prof, p);
    path.value = p;
    entries.value = list;
  } catch {
    toast.show("Ordner konnte nicht geladen werden");
  } finally {
    loading.value = false;
  }
}

function onEntry(e: FileEntry): void {
  if (e.is_dir) load(e.path);
}

function goUp(): void {
  const cur = path.value;
  const sep = cur.includes("\\") ? "\\" : "/";
  const trimmed = cur.replace(/[\\/]+$/, "");
  const idx = trimmed.lastIndexOf(sep);
  if (idx <= 2) {
    load("");
  } else {
    load(trimmed.slice(0, idx + 1));
  }
}

function downloadUrl(e: FileEntry): string {
  return profile.value ? api.fileDownloadUrl(profile.value, e.path) : "#";
}

async function openOnPc(e: FileEntry, ev: Event): Promise<void> {
  ev.stopPropagation();
  const p = profile.value;
  if (!p) return;
  try {
    await api.openFileOnPc(p, e.path);
    toast.show("Auf dem PC geöffnet ↗️");
  } catch {
    toast.show("Öffnen fehlgeschlagen");
  }
}

async function upload(ev: Event): Promise<void> {
  const input = ev.target as HTMLInputElement;
  const file = input.files?.[0];
  const p = profile.value;
  if (!file || !p || !path.value) return;
  toast.show("Lade hoch…");
  try {
    await api.uploadFile(p, path.value, file);
    toast.show("Hochgeladen ✅");
    load(path.value);
  } catch {
    toast.show("Upload fehlgeschlagen");
  } finally {
    input.value = "";
  }
}

function size(bytes: number): string {
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  if (bytes < 1024 * 1024 * 1024)
    return `${(bytes / 1024 / 1024).toFixed(1)} MB`;
  return `${(bytes / 1024 / 1024 / 1024).toFixed(1)} GB`;
}
</script>
