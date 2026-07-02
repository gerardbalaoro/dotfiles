import { loadConfig, type LoadConfigOptions } from "c12";
import { z } from "zod";
import { linkSync, mkdirSync, unlinkSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { randomBytes } from "node:crypto";

const ModelSchema = z
  .string()
  .regex(/^[^/]+\/[^/]+$/, "Model must be in `provider/model` form")
  .describe("AI model identifier in provider/model format");

const AgentSchema = z.object({
  model: ModelSchema,
  variant: z.string().optional().describe("Default model variant for this agent"),
});
export type Agent = z.infer<typeof AgentSchema>;

const PresetSchema = z.object({
  name: z.string().describe("The preset's display name"),
  description: z.string().describe("A short description about the preset"),
  model: ModelSchema.optional(),
  variant: z.string().optional().describe("Default model variant for this preset"),
  agent: z
    .record(z.string(), AgentSchema)
    .optional()
    .describe("The preset's model preferences for agents"),
});
export type Preset = z.infer<typeof PresetSchema>;

export const ConfigSchema = z.record(z.string(), PresetSchema);
export type Config = z.infer<typeof ConfigSchema>;

export const DEFAULT_PRESET_ID = "default";
export const DEFAULT_PRESET: Preset = {
  name: "Default",
  description: "Your default OpenCode model configuration",
};

/** Base name of the c12 config file (no extension). */
const CONFIG_BASENAME = "opencode.presets";
/** File scaffolded when no c12-supported presets config exists. */
const SCAFFOLD_FILENAME = `${CONFIG_BASENAME}.jsonc`;
/** `$schema` pointer written into the scaffolded file. */
const SCAFFOLD_SCHEMA = "./node_modules/opencode-model-presets/config.schema.json";

/**
 * Scaffold a minimal `opencode.presets.jsonc` containing only the `$schema`
 * pointer. Call only after c12's `loadConfig` confirms no supported presets
 * config file was resolved, so c12's own search logic (SUPPORTED_EXTENSIONS
 * order, `.config/` nesting, `index` forms) is the single source of truth
 * for whether a file already exists.
 *
 * Race strategy: write a same-directory temp file, then `linkSync` it onto
 * the target. `link(2)` is atomic and does NOT replace an existing file — it
 * fails with `EEXIST` instead, which we treat as success (a concurrent
 * creator won the race). The temp file is always cleaned up.
 */
function scaffoldPresetsFile(configDir: string): void {
  mkdirSync(configDir, { recursive: true });
  const target = join(configDir, SCAFFOLD_FILENAME);
  const content = JSON.stringify({ $schema: SCAFFOLD_SCHEMA }, null, 2) + "\n";
  const tmp = join(configDir, `.${randomBytes(8).toString("hex")}.tmp`);
  writeFileSync(tmp, content);
  try {
    try {
      // Atomic no-replace hard link. EEXIST → a concurrent process already
      // created the target; treat as success.
      linkSync(tmp, target);
    } catch (e) {
      if ((e as NodeJS.ErrnoException).code !== "EEXIST") throw e;
    }
  } finally {
    try {
      unlinkSync(tmp);
    } catch {
      // temp already gone
    }
  }
}

export interface ResolvedConfig {
  presets: Config;
  path: string;
}

export interface ConfigError {
  path: string;
  message: string;
}

export interface ConfigLoadResult {
  config: ResolvedConfig | null;
  error: ConfigError | null;
}

/**
 * Lazy live-reloading config holder backed by c12's `loadConfig`.
 *
 * `refresh()` re-runs c12 on every call (c12 re-reads the file), with a
 * short time-based throttle to avoid redundant loads on hot paths. On a
 * load or schema error the last valid config is retained and the error is
 * exposed via `lastError()`. `getCached()` returns the last valid config
 * synchronously for render paths.
 *
 * Limitation: c12 parses `.jsonc` via `confbox`, whose behavior splits in
 * two, so the two cases must not be conflated:
 *
 * - Malformed NON-EMPTY JSONC (e.g. `{ this is not json`): confbox silently
 *   returns `{}` (no throw). Such edits are indistinguishable from an
 *   intentionally empty config and so are treated as empty config (the
 *   synthetic default applies) rather than retained.
 * - Empty or comments-only `.jsonc` (including whitespace-only): c12 v4
 *   THROWS a `TypeError` (caught here). ConfigStore retains the last valid
 *   config and exposes the error via `lastError()`; the file is not treated
 *   as empty config and no scaffold is written over it.
 *
 * Schema (zod) errors and other c12-thrown load errors (e.g. `.json` syntax
 * errors) are likewise retained and exposed via `lastError()`.
 */
export class ConfigStore {
  private readonly configDir: string;
  private cached: ResolvedConfig | null = null;
  private error: ConfigError | null = null;
  private lastLoadMs = 0;
  private pending: Promise<ResolvedConfig | null> | null = null;
  private readonly throttleMs = 500;

  constructor(configDir: string) {
    this.configDir = configDir;
  }

  /** Synchronously return the last valid config (may be null before first load). */
  getCached(): ResolvedConfig | null {
    return this.cached;
  }

  /**
   * Reload config via c12. Returns the current valid config (last valid on
   * error). Pass `true` to bypass the time-based throttle.
   */
  async refresh(force = false): Promise<ResolvedConfig | null> {
    if (this.pending) return this.pending;
    if (!force && Date.now() - this.lastLoadMs < this.throttleMs) {
      return this.cached;
    }
    this.pending = this.load().finally(() => {
      this.pending = null;
    });
    return this.pending;
  }

  /** Alias for `refresh()`; convenience for callers that always want fresh. */
  async get(): Promise<ResolvedConfig | null> {
    return this.refresh();
  }

  /** Shared c12 options for every load in this store. */
  private loadOptions(): LoadConfigOptions {
    return {
      cwd: this.configDir,
      configFile: "opencode.presets",
      rcFile: false,
      packageJson: false,
      dotenv: false,
      extend: false,
      configFileRequired: false,
      // Strip top-level `$`-prefixed keys (e.g. `$schema`) before schema
      // validation so the scaffold loads as empty presets.
      omit$Keys: true,
    };
  }

  private async load(): Promise<ResolvedConfig | null> {
    this.lastLoadMs = Date.now();
    try {
      // Let c12 resolve the config file using its full search logic
      // (SUPPORTED_EXTENSIONS order, `.config/` nesting, `index` forms).
      // `_configFile` is set by c12 only when a real file was resolved and
      // loaded; it is `undefined` when no supported file exists. If nothing
      // resolved, scaffold a minimal file and reload so editor tooling picks
      // up the generated JSON Schema. No-clobber and cross-process race-safe
      // (see `scaffoldPresetsFile`).
      let result = await loadConfig(this.loadOptions());
      if (!result._configFile) {
        scaffoldPresetsFile(this.configDir);
        result = await loadConfig(this.loadOptions());
      }
      const parsed = ConfigSchema.parse(result.config ?? {});
      const resolved: ResolvedConfig = {
        presets: parsed,
        path: result._configFile ?? this.configDir,
      };
      this.cached = resolved;
      this.error = null;
      return resolved;
    } catch (e) {
      const message = e instanceof Error ? e.message : String(e);
      this.error = { path: this.configDir, message };
      // retain last valid config; auto-recover on next valid load
      return this.cached;
    }
  }

  lastError(): ConfigError | null {
    return this.error;
  }
}
