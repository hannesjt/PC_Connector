import type { PcProfile } from "~/types/models";

const KEY = "pc_connector_profiles";

export function useProfiles() {
  const profiles = useState<PcProfile[]>("profiles", () => []);

  function load(): void {
    if (!import.meta.client) return;
    try {
      const raw = localStorage.getItem(KEY);
      profiles.value = raw ? (JSON.parse(raw) as PcProfile[]) : [];
    } catch {
      profiles.value = [];
    }
  }

  function persist(list: PcProfile[]): void {
    if (import.meta.client) localStorage.setItem(KEY, JSON.stringify(list));
    profiles.value = list;
  }

  function getById(id: string): PcProfile | undefined {
    return profiles.value.find((p) => p.id === id);
  }

  function add(p: PcProfile): void {
    persist([...profiles.value, p]);
  }

  function update(p: PcProfile): void {
    persist(profiles.value.map((x) => (x.id === p.id ? p : x)));
  }

  function remove(id: string): void {
    persist(profiles.value.filter((x) => x.id !== id));
  }

  function newId(): string {
    return Date.now().toString() + Math.random().toString(36).slice(2, 6);
  }

  return { profiles, load, getById, add, update, remove, newId };
}
