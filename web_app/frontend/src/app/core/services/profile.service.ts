import { Injectable, signal } from "@angular/core";
import { PcProfile } from "../models/pc-profile.model";

const KEY = "pc_connector_profiles";

@Injectable({ providedIn: "root" })
export class ProfileService {
  readonly profiles = signal<PcProfile[]>(this.load());

  private load(): PcProfile[] {
    try {
      const raw = localStorage.getItem(KEY);
      return raw ? (JSON.parse(raw) as PcProfile[]) : [];
    } catch {
      return [];
    }
  }

  private persist(list: PcProfile[]): void {
    localStorage.setItem(KEY, JSON.stringify(list));
    this.profiles.set(list);
  }

  getById(id: string): PcProfile | undefined {
    return this.profiles().find((p) => p.id === id);
  }

  add(p: PcProfile): void {
    this.persist([...this.profiles(), p]);
  }

  update(p: PcProfile): void {
    this.persist(this.profiles().map((x) => (x.id === p.id ? p : x)));
  }

  remove(id: string): void {
    this.persist(this.profiles().filter((x) => x.id !== id));
  }

  newId(): string {
    return Date.now().toString() + Math.random().toString(36).slice(2, 6);
  }
}
