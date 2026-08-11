import type {
  DiscoveredAgent,
  FileEntry,
  PairResult,
  PcProfile,
  ScriptChain,
  ScriptConfig,
  ScriptResult,
} from "~/types/models";
import { baseUrl, mapChain, mapResult, mapScript } from "~/types/models";

export function useApi() {
  const backendBase = useRuntimeConfig().public.backendBase || "";

  function headers(p: PcProfile): Record<string, string> {
    const h: Record<string, string> = { "X-Agent-Base": baseUrl(p) };
    if (p.deviceToken) h["Authorization"] = `Bearer ${p.deviceToken}`;
    return h;
  }

  const u = (path: string) => `${backendBase}/proxy${path}`;

  async function pair(
    base: string,
    code: string,
    deviceName: string,
  ): Promise<PairResult> {
    return $fetch<PairResult>(u("/api/pair"), {
      method: "POST",
      headers: { "X-Agent-Base": base },
      body: { code, device_name: deviceName },
    });
  }

  async function isOnline(p: PcProfile): Promise<boolean> {
    try {
      await $fetch(u("/api/status"), { headers: headers(p) });
      return true;
    } catch {
      return false;
    }
  }

  function status(p: PcProfile): Promise<any> {
    return $fetch<any>(u("/api/status"), { headers: headers(p) });
  }

  async function getScripts(p: PcProfile): Promise<ScriptConfig[]> {
    const d = await $fetch<any[]>(u("/api/scripts"), { headers: headers(p) });
    return d.map(mapScript);
  }

  async function runScript(p: PcProfile, id: string): Promise<ScriptResult> {
    const d = await $fetch<any>(u(`/api/scripts/${id}/run`), {
      method: "POST",
      headers: headers(p),
      body: {},
    });
    return mapResult(d);
  }

  async function getChains(p: PcProfile): Promise<ScriptChain[]> {
    const d = await $fetch<any[]>(u("/api/chains"), { headers: headers(p) });
    return d.map(mapChain);
  }

  function runChain(p: PcProfile, id: string): Promise<any> {
    return $fetch<any>(u(`/api/chains/${id}/run`), {
      method: "POST",
      headers: headers(p),
      body: {},
    });
  }

  async function getCategories(p: PcProfile): Promise<string[]> {
    try {
      const d = await $fetch<any>(u("/api/categories"), {
        headers: headers(p),
      });
      return (d?.ordered ?? []) as string[];
    } catch {
      return [];
    }
  }

  function mouseMove(p: PcProfile, dx: number, dy: number): Promise<any> {
    return $fetch(u("/api/input/mouse/move"), {
      method: "POST",
      headers: headers(p),
      body: { dx, dy },
    });
  }
  function mouseClick(
    p: PcProfile,
    button = "left",
    double = false,
  ): Promise<any> {
    return $fetch(u("/api/input/mouse/click"), {
      method: "POST",
      headers: headers(p),
      body: { button, double },
    });
  }
  function mouseScroll(p: PcProfile, dx = 0, dy = 0): Promise<any> {
    return $fetch(u("/api/input/mouse/scroll"), {
      method: "POST",
      headers: headers(p),
      body: { dx, dy },
    });
  }
  function keyboardType(p: PcProfile, text: string): Promise<any> {
    return $fetch(u("/api/input/keyboard/type"), {
      method: "POST",
      headers: headers(p),
      body: { text },
    });
  }
  function keyboardKey(p: PcProfile, key: string): Promise<any> {
    return $fetch(u("/api/input/keyboard/key"), {
      method: "POST",
      headers: headers(p),
      body: { key },
    });
  }

  function getVolume(p: PcProfile): Promise<any> {
    return $fetch<any>(u("/api/volume/"), { headers: headers(p) });
  }
  function setVolume(p: PcProfile, level: number): Promise<any> {
    return $fetch(u("/api/volume/set"), {
      method: "POST",
      headers: headers(p),
      body: { level },
    });
  }
  function setMute(p: PcProfile, muted: boolean): Promise<any> {
    return $fetch(u("/api/volume/mute"), {
      method: "POST",
      headers: headers(p),
      body: { muted },
    });
  }

  async function getClipboard(p: PcProfile): Promise<string> {
    try {
      const d = await $fetch<any>(u("/api/clipboard/"), {
        headers: headers(p),
      });
      return (d?.text as string) ?? "";
    } catch {
      return "";
    }
  }
  function setClipboard(p: PcProfile, text: string): Promise<any> {
    return $fetch(u("/api/clipboard/set"), {
      method: "POST",
      headers: headers(p),
      body: { text },
    });
  }

  function listFiles(p: PcProfile, path: string): Promise<FileEntry[]> {
    return $fetch<FileEntry[]>(u("/api/files/list"), {
      headers: headers(p),
      query: { path },
    });
  }
  function uploadFile(p: PcProfile, dest: string, file: File): Promise<any> {
    const fd = new FormData();
    fd.append("file", file, file.name);
    return $fetch(u("/api/files/upload"), {
      method: "POST",
      headers: headers(p),
      query: { dest },
      body: fd,
    });
  }
  function openFileOnPc(p: PcProfile, path: string): Promise<any> {
    return $fetch(u("/api/files/open"), {
      method: "POST",
      headers: headers(p),
      query: { path },
      body: {},
    });
  }
  function fileDownloadUrl(p: PcProfile, path: string): string {
    const b = encodeURIComponent(baseUrl(p));
    return `${backendBase}/proxy/api/files/download?path=${encodeURIComponent(
      path,
    )}&__base=${b}&__token=${p.deviceToken}`;
  }

  function screenshotUrl(p: PcProfile, quality = 50, scale = 0.5): string {
    const b = encodeURIComponent(baseUrl(p));
    return `${backendBase}/proxy/api/screen/screenshot?quality=${quality}&scale=${scale}&__base=${b}&__token=${p.deviceToken}&_t=${Date.now()}`;
  }

  async function getHistory(p: PcProfile, limit = 50): Promise<any[]> {
    try {
      return await $fetch<any[]>(u(`/api/history/?limit=${limit}`), {
        headers: headers(p),
      });
    } catch {
      return [];
    }
  }
  function clearHistory(p: PcProfile): Promise<any> {
    return $fetch(u("/api/history/"), {
      method: "DELETE",
      headers: headers(p),
    });
  }

  function wol(
    mac: string,
    broadcast = "255.255.255.255",
    port = 9,
  ): Promise<any> {
    return $fetch(`${backendBase}/api/wol`, {
      method: "POST",
      body: { mac, broadcast, port },
    });
  }
  function discover(): Promise<DiscoveredAgent[]> {
    return $fetch<DiscoveredAgent[]>(`${backendBase}/api/discover`);
  }

  return {
    pair,
    isOnline,
    status,
    getScripts,
    runScript,
    getChains,
    runChain,
    getCategories,
    mouseMove,
    mouseClick,
    mouseScroll,
    keyboardType,
    keyboardKey,
    getVolume,
    setVolume,
    setMute,
    getClipboard,
    setClipboard,
    listFiles,
    uploadFile,
    openFileOnPc,
    fileDownloadUrl,
    screenshotUrl,
    getHistory,
    clearHistory,
    wol,
    discover,
  };
}
