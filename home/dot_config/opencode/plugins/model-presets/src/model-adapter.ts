import type { Config, ResolvedConfig } from "./config";
import { DEFAULT_PRESET_ID } from "./config";

/**
 * Model reference in `provider/model` form, split into the two parts the
 * OpenCode message model expects.
 */
export interface ModelRef {
  providerID: string;
  modelID: string;
  variant?: string;
}

export function parseModelRef(ref: string): ModelRef {
  const slash = ref.indexOf("/");
  if (slash <= 0 || slash >= ref.length - 1) {
    throw new Error(`invalid model reference: ${ref}`);
  }
  return { providerID: ref.slice(0, slash), modelID: ref.slice(slash + 1) };
}

export interface OriginalModel {
  providerID: string;
  modelID: string;
  variant?: string;
}

function withVariant(model: ModelRef, variant: string | undefined): ModelRef {
  return variant ? { ...model, variant } : model;
}

/**
 * Resolve the effective model for a message.
 *
 * Resolution order per the spec:
 *   agent entry `{ model, variant }` > preset-level `{ model, variant }` > original
 *
 * An agent entry's omitted variant falls back to the preset variant, then the
 * original. A preset with no `model`/`agent` overrides falls back entirely to
 * the original OpenCode model+variant.
 *
 * The synthetic `default` selection (untouched OpenCode config) applies when
 * the selected preset id is missing from the config, or when the id is
 * `default` and the user has not defined a `default` preset. If a saved
 * selection disappears from the config (e.g. it was removed in an edit), it
 * routes to the synthetic default WITHOUT overwriting the saved selection,
 * so a later restore of the preset resumes seamlessly.
 */
export function resolveModel(
  config: ResolvedConfig,
  presetId: string | null,
  agentName: string | undefined,
  original: OriginalModel,
): { model: ModelRef; preset: string; routedDefault: boolean } {
  const presets: Config = config.presets;
  let resolvedId = presetId;
  let routedDefault = false;

  if (!resolvedId || !(resolvedId in presets)) {
    resolvedId = DEFAULT_PRESET_ID;
    routedDefault = presetId !== null && presetId !== DEFAULT_PRESET_ID;
  }

  const preset = presets[resolvedId];
  if (!preset) {
    // Synthetic default: untouched OpenCode model config.
    return { model: { ...original }, preset: DEFAULT_PRESET_ID, routedDefault };
  }

  const agentEntry = agentName ? preset.agent?.[agentName] : undefined;

  if (agentEntry) {
    const ref = parseModelRef(agentEntry.model);
    const variant = agentEntry.variant ?? preset.variant ?? original.variant;
    return { model: withVariant(ref, variant), preset: resolvedId, routedDefault };
  }

  if (preset.model) {
    const ref = parseModelRef(preset.model);
    const variant = preset.variant ?? original.variant;
    return { model: withVariant(ref, variant), preset: resolvedId, routedDefault };
  }

  // No model/agent overrides: fall back to original OpenCode model+variant.
  return { model: { ...original }, preset: resolvedId, routedDefault };
}

/**
 * Isolate the unsupported OpenCode behavior of mutating the outbound user
 * message's model in place. The `chat.message` hook hands us `output.message`
 * and we rewrite its `model` field to the resolved preset model.
 */
export function applyModelToMessage(message: { model: OriginalModel }, model: ModelRef): void {
  message.model = { providerID: model.providerID, modelID: model.modelID };
}

/** Apply the effective variant through the hook's dedicated variant input. */
export function applyVariantToInput(
  input: { variant?: string },
  variant: string | undefined,
): void {
  input.variant = variant;
}
