import type { TuiPlugin, TuiPluginModule } from "@opencode-ai/plugin/tui";
import { onCleanup } from "solid-js";
import { ConfigStore } from "./config";
import { StateStore } from "./state";
import { Indicator } from "./components/indicator";
import { openPresetPicker } from "./components/picker";

const tui: TuiPlugin = async (api, _options) => {
  const configDir = api.state.path.config;
  const stateDir = api.state.path.state;
  const configStore = new ConfigStore(configDir);
  const state = new StateStore(stateDir);
  state.ensure();

  // Best-effort initial load so the picker/indicator have config on first paint.
  void configStore.refresh();

  // Resolve the current session id from the route (best-effort).
  const currentSessionId = (): string | undefined => {
    const route = api.route.current;
    if (route.name === "session" && typeof route.params?.sessionID === "string") {
      return route.params.sessionID as string;
    }
    return undefined;
  };

  api.slots.register({
    order: 160,
    slots: {
      home_prompt_right() {
        return <Indicator api={api} configStore={configStore} state={state} />;
      },
      session_prompt_right(_ctx, props) {
        return (
          <Indicator
            api={api}
            configStore={configStore}
            state={state}
            session_id={props.session_id}
          />
        );
      },
    },
  });

  // When the user switches to an existing session, restore that session's
  // saved preset and update `last`. Polling the route is the deterministic
  // cross-version way to observe switches without relying on reactive route
  // signals.
  let lastSeenSession: string | undefined = undefined;
  const routeTimer = setInterval(() => {
    const id = currentSessionId();
    if (id && id !== lastSeenSession) {
      lastSeenSession = id;
      const saved = state.getSessionPreset(id);
      if (saved) state.setLastPreset(saved);
    }
  }, 500);
  onCleanup(() => clearInterval(routeTimer));

  // Force a c12 refresh before rendering the picker synchronously.
  // This closes the race where `getCached()` is read before the initial async
  // load completes and a false no-config error is shown. `refresh()` never
  // rejects (it retains the last valid config on error), but the await is
  // wrapped defensively in case a future load path throws.
  const refreshForCommand = async (): Promise<void> => {
    try {
      await configStore.refresh(true);
    } catch {
      // swallow: cached/error UI surfaces the failure
    }
  };

  const handlePresetCommand = async (): Promise<void> => {
    const id = currentSessionId();
    await refreshForCommand();
    openPresetPicker({ api, configStore, state, session_id: id });
  };

  // Register slash commands + palette actions. The legacy `api.command` API
  // is the deterministic cross-version way to register zero-LLM slash
  // commands in 1.18.3.
  if (api.command) {
    const unregister = api.command.register(() => [
      {
        title: "Switch model preset",
        value: "presets",
        category: "Agent",
        slash: { name: "presets" },
        onSelect: () => handlePresetCommand(),
      },
    ]);
    onCleanup(() => unregister());
  }
};

export default { id: "model-presets", tui } satisfies TuiPluginModule;
