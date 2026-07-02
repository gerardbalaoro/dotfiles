import {
  existsSync,
  mkdirSync,
  readFileSync,
  writeFileSync,
  unlinkSync,
  renameSync,
} from "node:fs";
import { join } from "node:path";
import { randomBytes } from "node:crypto";
import { DEFAULT_PRESET_ID } from "./config";

/**
 * Session-preserved preset selection state.
 *
 * Layout under the resolved OpenCode state directory:
 *   <state>/model-presets/last.json          # last selected preset id
 *   <state>/model-presets/sessions/<id>.json  # per-session preset id
 *
 * All writes are atomic (temp file in the same dir + rename). Missing state
 * defaults to the synthetic `default` selection (untouched OpenCode config).
 * A persisted `default` from the previous schema (which held custom overrides)
 * routes safely to the synthetic default after the refactor; users can
 * re-select a renamed preset to restore custom overrides.
 */

export interface SelectedState {
  /** The preset id selected for this session. */
  preset: string;
}

const STATE_SUBDIR = "model-presets";
const SESSIONS_SUBDIR = "sessions";

export class StateStore {
  private readonly baseDir: string;
  private readonly sessionsDir: string;

  constructor(stateDir: string) {
    this.baseDir = join(stateDir, STATE_SUBDIR);
    this.sessionsDir = join(this.baseDir, SESSIONS_SUBDIR);
  }

  /** Ensure the state directories exist. Safe to call repeatedly. */
  ensure(): void {
    mkdirSync(this.baseDir, { recursive: true });
    mkdirSync(this.sessionsDir, { recursive: true });
  }

  private atomicWrite(path: string, text: string): void {
    this.ensure();
    const dir = join(path, "..");
    const tmp = join(dir, `.${randomBytes(6).toString("hex")}.tmp`);
    writeFileSync(tmp, text);
    renameSync(tmp, path);
  }

  private readJson<T>(path: string): T | null {
    if (!existsSync(path)) return null;
    try {
      return JSON.parse(readFileSync(path, "utf8")) as T;
    } catch {
      return null;
    }
  }

  // ---- last selected preset ----

  getLastPreset(): string {
    const data = this.readJson<{ preset: string }>(join(this.baseDir, "last.json"));
    return data?.preset ?? DEFAULT_PRESET_ID;
  }

  setLastPreset(presetId: string): void {
    this.atomicWrite(join(this.baseDir, "last.json"), JSON.stringify({ preset: presetId }));
  }

  // ---- per-session preset ----

  private sessionPath(sessionId: string): string {
    return join(this.sessionsDir, `${sessionId}.json`);
  }

  getSessionPreset(sessionId: string): string | null {
    const data = this.readJson<{ preset: string }>(this.sessionPath(sessionId));
    return data?.preset ?? null;
  }

  setSessionPreset(sessionId: string, presetId: string): void {
    this.atomicWrite(this.sessionPath(sessionId), JSON.stringify({ preset: presetId }));
  }

  deleteSessionPreset(sessionId: string): void {
    const path = this.sessionPath(sessionId);
    try {
      unlinkSync(path);
    } catch {
      // already gone
    }
  }

  /**
   * Ensure a session has a saved preset, inheriting from its parent or the
   * last selection. Does not overwrite an existing selection.
   */
  ensureSessionPreset(sessionId: string, parentID?: string): string {
    const existing = this.getSessionPreset(sessionId);
    if (existing) return existing;
    const inherited = parentID
      ? (this.getSessionPreset(parentID) ?? this.getLastPreset())
      : this.getLastPreset();
    this.setSessionPreset(sessionId, inherited);
    return inherited;
  }
}
