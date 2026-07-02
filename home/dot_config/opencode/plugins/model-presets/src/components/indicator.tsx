import type { TuiPluginApi } from "@opencode-ai/plugin/tui";
import { createMemo, createSignal, onCleanup } from "solid-js";
import { DEFAULT_PRESET, DEFAULT_PRESET_ID, type ConfigStore } from "../config";
import type { StateStore } from "../state";

export function Indicator(props: {
  api: TuiPluginApi;
  configStore: ConfigStore;
  state: StateStore;
  session_id?: string;
}) {
  const [version, setVersion] = createSignal(0);
  const timer = setInterval(() => {
    void props.configStore.refresh().then(() => setVersion((value) => value + 1));
  }, 1000);
  onCleanup(() => clearInterval(timer));

  const name = createMemo(() => {
    version();
    const config = props.configStore.getCached();
    if (!config) return "";
    const presetId =
      (props.session_id && props.state.getSessionPreset(props.session_id)) ??
      props.state.getLastPreset() ??
      DEFAULT_PRESET_ID;
    return config.presets[presetId]?.name ?? DEFAULT_PRESET.name;
  });

  return <text fg={props.api.theme.current.textMuted}>{name()}</text>;
}
