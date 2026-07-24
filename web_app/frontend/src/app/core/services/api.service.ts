import { Injectable, inject } from "@angular/core";
import { HttpClient, HttpHeaders, HttpParams } from "@angular/common/http";
import { firstValueFrom } from "rxjs";
import { PcProfile, baseUrl } from "../models/pc-profile.model";
import {
  DiscoveredAgent,
  FileEntry,
  ScriptChain,
  ScriptConfig,
  ScriptResult,
  mapChain,
  mapResult,
  mapScript,
} from "../models/script.model";

export interface PairResult {
  success: boolean;
  token?: string;
  message?: string;
  mac_address?: string;
  pc_name?: string;
}

@Injectable({ providedIn: "root" })
export class ApiService {
  private http = inject(HttpClient);

  private headers(p: PcProfile): HttpHeaders {
    let h = new HttpHeaders().set("X-Agent-Base", baseUrl(p));
    if (p.deviceToken) h = h.set("Authorization", `Bearer ${p.deviceToken}`);
    return h;
  }

  private u(path: string): string {
    return `/proxy${path}`;
  }

  // --- Pairing (no token) ---
  async pair(
    base: string,
    code: string,
    deviceName: string,
  ): Promise<PairResult> {
    const headers = new HttpHeaders().set("X-Agent-Base", base);
    return firstValueFrom(
      this.http.post<PairResult>(
        this.u("/api/pair"),
        { code, device_name: deviceName },
        { headers },
      ),
    );
  }

  // --- Status ---
  async isOnline(p: PcProfile): Promise<boolean> {
    try {
      await firstValueFrom(
        this.http.get(this.u("/api/status"), { headers: this.headers(p) }),
      );
      return true;
    } catch {
      return false;
    }
  }

  status(p: PcProfile): Promise<any> {
    return firstValueFrom(
      this.http.get<any>(this.u("/api/status"), { headers: this.headers(p) }),
    );
  }

  // --- Scripts ---
  async getScripts(p: PcProfile): Promise<ScriptConfig[]> {
    const d = await firstValueFrom(
      this.http.get<any[]>(this.u("/api/scripts"), {
        headers: this.headers(p),
      }),
    );
    return d.map(mapScript);
  }

  async runScript(p: PcProfile, id: string): Promise<ScriptResult> {
    const d = await firstValueFrom(
      this.http.post<any>(
        this.u(`/api/scripts/${id}/run`),
        {},
        { headers: this.headers(p) },
      ),
    );
    return mapResult(d);
  }

  async getChains(p: PcProfile): Promise<ScriptChain[]> {
    const d = await firstValueFrom(
      this.http.get<any[]>(this.u("/api/chains"), { headers: this.headers(p) }),
    );
    return d.map(mapChain);
  }

  runChain(p: PcProfile, id: string): Promise<any> {
    return firstValueFrom(
      this.http.post<any>(
        this.u(`/api/chains/${id}/run`),
        {},
        { headers: this.headers(p) },
      ),
    );
  }

  async getCategories(p: PcProfile): Promise<string[]> {
    try {
      const d = await firstValueFrom(
        this.http.get<any>(this.u("/api/categories"), {
          headers: this.headers(p),
        }),
      );
      return (d?.ordered ?? []) as string[];
    } catch {
      return [];
    }
  }

  // --- Input control ---
  mouseMove(p: PcProfile, dx: number, dy: number): Promise<any> {
    return firstValueFrom(
      this.http.post(
        this.u("/api/input/mouse/move"),
        { dx, dy },
        { headers: this.headers(p) },
      ),
    );
  }
  mouseClick(p: PcProfile, button = "left", double = false): Promise<any> {
    return firstValueFrom(
      this.http.post(
        this.u("/api/input/mouse/click"),
        { button, double },
        { headers: this.headers(p) },
      ),
    );
  }
  mouseScroll(p: PcProfile, dx = 0, dy = 0): Promise<any> {
    return firstValueFrom(
      this.http.post(
        this.u("/api/input/mouse/scroll"),
        { dx, dy },
        { headers: this.headers(p) },
      ),
    );
  }
  keyboardType(p: PcProfile, text: string): Promise<any> {
    return firstValueFrom(
      this.http.post(
        this.u("/api/input/keyboard/type"),
        { text },
        { headers: this.headers(p) },
      ),
    );
  }
  keyboardKey(p: PcProfile, key: string): Promise<any> {
    return firstValueFrom(
      this.http.post(
        this.u("/api/input/keyboard/key"),
        { key },
        { headers: this.headers(p) },
      ),
    );
  }

  // --- Volume ---
  getVolume(p: PcProfile): Promise<any> {
    return firstValueFrom(
      this.http.get<any>(this.u("/api/volume/"), { headers: this.headers(p) }),
    );
  }
  setVolume(p: PcProfile, level: number): Promise<any> {
    return firstValueFrom(
      this.http.post(
        this.u("/api/volume/set"),
        { level },
        { headers: this.headers(p) },
      ),
    );
  }
  setMute(p: PcProfile, muted: boolean): Promise<any> {
    return firstValueFrom(
      this.http.post(
        this.u("/api/volume/mute"),
        { muted },
        { headers: this.headers(p) },
      ),
    );
  }

  // --- Clipboard ---
  async getClipboard(p: PcProfile): Promise<string> {
    try {
      const d = await firstValueFrom(
        this.http.get<any>(this.u("/api/clipboard/"), {
          headers: this.headers(p),
        }),
      );
      return (d?.text as string) ?? "";
    } catch {
      return "";
    }
  }
  setClipboard(p: PcProfile, text: string): Promise<any> {
    return firstValueFrom(
      this.http.post(
        this.u("/api/clipboard/set"),
        { text },
        { headers: this.headers(p) },
      ),
    );
  }

  // --- Files ---
  listFiles(p: PcProfile, path: string): Promise<FileEntry[]> {
    const params = new HttpParams().set("path", path);
    return firstValueFrom(
      this.http.get<FileEntry[]>(this.u("/api/files/list"), {
        headers: this.headers(p),
        params,
      }),
    );
  }
  uploadFile(p: PcProfile, dest: string, file: File): Promise<any> {
    const fd = new FormData();
    fd.append("file", file, file.name);
    const params = new HttpParams().set("dest", dest);
    return firstValueFrom(
      this.http.post(this.u("/api/files/upload"), fd, {
        headers: this.headers(p),
        params,
      }),
    );
  }
  openFileOnPc(p: PcProfile, path: string): Promise<any> {
    const params = new HttpParams().set("path", path);
    return firstValueFrom(
      this.http.post(
        this.u("/api/files/open"),
        {},
        { headers: this.headers(p), params },
      ),
    );
  }
  fileDownloadUrl(p: PcProfile, path: string): string {
    const b = encodeURIComponent(baseUrl(p));
    return `/proxy/api/files/download?path=${encodeURIComponent(path)}&__base=${b}&__token=${p.deviceToken}`;
  }

  // --- Screen ---
  screenshotUrl(p: PcProfile, quality = 50, scale = 0.5): string {
    const b = encodeURIComponent(baseUrl(p));
    return `/proxy/api/screen/screenshot?quality=${quality}&scale=${scale}&__base=${b}&__token=${p.deviceToken}&_t=${Date.now()}`;
  }

  // --- History ---
  async getHistory(p: PcProfile, limit = 50): Promise<any[]> {
    try {
      return await firstValueFrom(
        this.http.get<any[]>(this.u(`/api/history/?limit=${limit}`), {
          headers: this.headers(p),
        }),
      );
    } catch {
      return [];
    }
  }
  clearHistory(p: PcProfile): Promise<any> {
    return firstValueFrom(
      this.http.delete(this.u("/api/history/"), { headers: this.headers(p) }),
    );
  }

  // --- WOL + discovery (handled by our own backend) ---
  wol(mac: string, broadcast = "255.255.255.255", port = 9): Promise<any> {
    return firstValueFrom(this.http.post("/api/wol", { mac, broadcast, port }));
  }
  discover(): Promise<DiscoveredAgent[]> {
    return firstValueFrom(this.http.get<DiscoveredAgent[]>("/api/discover"));
  }
}
