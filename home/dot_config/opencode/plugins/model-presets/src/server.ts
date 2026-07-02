import type { Plugin, PluginInput } from "@opencode-ai/plugin";
import type { Event } from "@opencode-ai/sdk";
import { ConfigStore } from "./config";
import { StateStore } from "./state";
import { resolveModel, applyModelToMessage, applyVariantToInput } from "./model-adapter";

const plugin: Plugin = async (input: PluginInput) => {
  const { client } = input;

  type Stores = { configStore: ConfigStore; state: StateStore };
  let storesPromise: Promise<Stores> | null = null;

  // Plugin registration runs while OpenCode is still bootstrapping its HTTP
  // server. Calling client.path.get() here waits on that server, while the
  // server is waiting for this plugin to finish registering. Resolve paths
  // lazily from the first real hook instead, after bootstrap has completed.
  const getStores = (): Promise<Stores> => {
    if (storesPromise) return storesPromise;
    storesPromise = (async () => {
      const pathRes = await client.path.get();
      const paths = pathRes.data;
      if (!paths) {
        throw new Error("model-presets: could not resolve paths from server");
      }

      const configStore = new ConfigStore(paths.config);
      const state = new StateStore(paths.state);
      state.ensure();

      // Best-effort initial load so the first message can share this request.
      void configStore.refresh();
      return { configStore, state };
    })().catch((error) => {
      // Allow a transient API failure to recover on the next hook.
      storesPromise = null;
      throw error;
    });
    return storesPromise;
  };

  // Best-effort log: surface config errors where the host can capture them.
  const reportConfigError = (configStore: ConfigStore) => {
    const err = configStore.lastError();
    if (err) {
      // The server plugin has no toast API; write to stderr for the host log.
      // eslint-disable-next-line no-console
      console.error(`[model-presets] config error (${err.path}): ${err.message}`);
    }
  };

  return {
    "chat.message": async (input, output) => {
      const { configStore, state } = await getStores();
      // Refresh config via c12 (throttled live reload).
      const config = await configStore.refresh();
      if (!config) {
        reportConfigError(configStore);
        return; // no valid config: leave original model untouched
      }

      const sessionID = input.sessionID;
      let presetId = state.getSessionPreset(sessionID);

      // Inherit if this session has no saved selection yet. Resolve parent
      // via the API so subagents inherit the parent's preset.
      if (presetId === null) {
        let parentID: string | undefined;
        try {
          const res = await client.session.get({ path: { id: sessionID } });
          parentID = res.data?.parentID;
        } catch {
          // ignore — treat as root
        }
        presetId = state.ensureSessionPreset(sessionID, parentID);
      }

      const originalModel = input.model ?? output.message.model;
      const original = {
        providerID: originalModel.providerID,
        modelID: originalModel.modelID,
        variant: input.variant,
      };
      const agent = input.agent ?? output.message.agent;

      const { model } = resolveModel(config, presetId, agent, original);
      // Isolate the unsupported mutation of the outbound message model.
      applyModelToMessage(output.message, model);
      applyVariantToInput(input, model.variant);
    },

    event: async ({ event }: { event: Event }) => {
      const { state } = await getStores();
      switch (event.type) {
        case "session.created": {
          const info = event.properties.info;
          // New root inherits last; child inherits parent.
          state.ensureSessionPreset(info.id, info.parentID);
          break;
        }
        case "session.deleted": {
          const info = event.properties.info;
          state.deleteSessionPreset(info.id);
          break;
        }
        default:
          break;
      }
    },
  };
};

export default plugin satisfies Plugin;
