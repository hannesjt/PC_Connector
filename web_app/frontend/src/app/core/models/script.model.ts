export interface ScriptConfig {
  id: string;
  name: string;
  icon: string;
  confirm: boolean;
  group: string;
  order: number;
  isGlobal: boolean;
}

export interface ScriptResult {
  scriptId: string;
  success: boolean;
  stdout: string;
  stderr: string;
  exitCode: number;
}

export interface ChainStep {
  scriptId: string;
  delaySeconds: number;
}

export interface ScriptChain {
  id: string;
  name: string;
  steps: ChainStep[];
  order: number;
}

export interface DiscoveredAgent {
  name: string;
  ip: string;
  port: number;
  mac: string;
}

export interface FileEntry {
  name: string;
  path: string;
  is_dir: boolean;
  size: number;
  modified: number;
}

/* ---- JSON (snake_case) -> model mappers -------------------------------- */

export function mapScript(j: any): ScriptConfig {
  return {
    id: j.id,
    name: j.name,
    icon: j.icon ?? "play_arrow",
    confirm: !!j.confirm,
    group: j.group ?? "",
    order: j.order ?? 0,
    isGlobal: !!j.is_global,
  };
}

export function mapResult(j: any): ScriptResult {
  return {
    scriptId: j.script_id,
    success: !!j.success,
    stdout: j.stdout ?? "",
    stderr: j.stderr ?? "",
    exitCode: j.exit_code ?? 0,
  };
}

export function mapChain(j: any): ScriptChain {
  return {
    id: j.id,
    name: j.name,
    order: j.order ?? 0,
    steps: (j.steps ?? []).map((s: any) => ({
      scriptId: s.script_id,
      delaySeconds: s.delay_seconds ?? 0,
    })),
  };
}
