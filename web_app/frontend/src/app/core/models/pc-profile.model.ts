export interface PcProfile {
  id: string;
  name: string;
  macAddress: string;
  ipAddress: string;
  port: number;
  deviceToken?: string | null;
  lastSeen?: number | null;
}

export function baseUrl(p: PcProfile): string {
  return `http://${p.ipAddress}:${p.port}`;
}
