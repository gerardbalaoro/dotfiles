import type { TuiPluginApi } from "@opencode-ai/plugin/tui";
import type { KeyEvent, ScrollBoxRenderable } from "@opentui/core";
import { For, createEffect, createMemo, createSignal } from "solid-js";
import type { ConfigStore, ResolvedConfig } from "../config";
import { DEFAULT_PRESET_ID, DEFAULT_PRESET } from "../config";
import type { StateStore } from "../state";

interface PickerOption {
  title: string;
  value: string;
  description: string;
}

function PresetPicker(props: {
  api: TuiPluginApi;
  options: PickerOption[];
  current: string;
  onSelect: (option: PickerOption) => void;
}) {
  const [query, setQuery] = createSignal("");
  const [selected, setSelected] = createSignal(props.current);
  let listRef: ScrollBoxRenderable | undefined;

  const filtered = createMemo(() => {
    const needle = query().trim().toLocaleLowerCase();
    if (!needle) return props.options;
    return props.options.filter((option) =>
      `${option.value} ${option.title} ${option.description}`.toLocaleLowerCase().includes(needle),
    );
  });

  createEffect(() => {
    const options = filtered();
    if (!options.length) {
      setSelected("");
      return;
    }
    if (!options.some((option) => option.value === selected())) {
      setSelected(options[0].value);
    }
  });

  createEffect(() => {
    const value = selected();
    if (!value) return;
    const index = props.options.findIndex((option) => option.value === value);
    if (index < 0) return;
    queueMicrotask(() => listRef?.scrollChildIntoView(`model-preset-option-${index}`));
  });

  const move = (delta: number) => {
    const options = filtered();
    if (!options.length) return;
    const index = options.findIndex((option) => option.value === selected());
    const next = index < 0 ? 0 : (index + delta + options.length) % options.length;
    setSelected(options[next].value);
  };

  const chooseSelected = () => {
    const option = filtered().find((item) => item.value === selected());
    if (option) props.onSelect(option);
  };

  const onKeyDown = (event: KeyEvent) => {
    if (event.name === "up" || event.name === "down") {
      event.preventDefault();
      event.stopPropagation();
      move(event.name === "up" ? -1 : 1);
      return;
    }
    if (event.name === "escape" || event.name === "esc") {
      event.preventDefault();
      event.stopPropagation();
      props.api.ui.dialog.clear();
    }
  };

  const theme = () => props.api.theme.current;

  return (
    <box width="100%" minWidth={0} gap={1} paddingBottom={1}>
      <box width="100%" minWidth={0} gap={1} paddingLeft={4} paddingRight={4}>
        <text fg={theme().text}>
          <b>Select preset</b>
        </text>
        <input
          focused={true}
          placeholder="Search"
          value={query()}
          onInput={setQuery}
          onSubmit={chooseSelected}
          onKeyDown={onKeyDown}
          textColor={theme().text}
          focusedTextColor={theme().text}
          placeholderColor={theme().textMuted}
        />
      </box>
      <scrollbox
        ref={listRef}
        width="100%"
        minWidth={0}
        paddingLeft={2}
        paddingRight={2}
        maxHeight={20}
        flexShrink={1}
        scrollY={true}
      >
        <box width="100%" minWidth={0} gap={1}>
          <For each={filtered()}>
            {(option) => {
              const optionIndex = props.options.indexOf(option);
              const isSelected = () => selected() === option.value;
              return (
                <box
                  id={`model-preset-option-${optionIndex}`}
                  width="100%"
                  minWidth={0}
                  flexDirection="row"
                  backgroundColor={isSelected() ? theme().primary : theme().backgroundPanel}
                  onMouseUp={() => props.onSelect(option)}
                >
                  <text
                    width={2}
                    flexShrink={0}
                    fg={
                      option.value === props.current
                        ? isSelected()
                          ? theme().selectedListItemText
                          : theme().accent
                        : theme().textMuted
                    }
                  >
                    {option.value === props.current ? "● " : "  "}
                  </text>
                  <box minWidth={0} flexGrow={1}>
                    <text
                      width="100%"
                      fg={isSelected() ? theme().selectedListItemText : theme().text}
                      wrapMode="word"
                    >
                      <b>{option.title}</b>
                    </text>
                    <text
                      width="100%"
                      fg={isSelected() ? theme().selectedListItemText : theme().textMuted}
                      wrapMode="word"
                    >
                      {option.description}
                    </text>
                  </box>
                </box>
              );
            }}
          </For>
        </box>
      </scrollbox>
      <box
        width="100%"
        minWidth={0}
        flexDirection="row"
        justifyContent="flex-end"
        paddingLeft={4}
        paddingRight={4}
      >
        <text fg={theme().textMuted}>↑/↓ navigate · enter select · esc close</text>
      </box>
    </box>
  );
}

export function openPresetPicker(props: {
  api: TuiPluginApi;
  configStore: ConfigStore;
  state: StateStore;
  session_id?: string;
}): void {
  const { api, configStore, state, session_id } = props;
  const config: ResolvedConfig | null = configStore.getCached();
  if (!config) {
    const err = configStore.lastError();
    api.ui.toast({
      variant: "error",
      title: "Model presets",
      message: err?.message ?? "No presets configuration",
    });
    return;
  }

  const current = session_id
    ? (state.getSessionPreset(session_id) ?? DEFAULT_PRESET_ID)
    : state.getLastPreset();
  const hasUserDefault = DEFAULT_PRESET_ID in config.presets;

  // Build the picker options. The synthetic `default` (untouched OpenCode
  // config) is always available unless the user has defined a `default`
  // preset that shadows it.
  const options = Object.entries(config.presets)
    .sort(([a], [b]) =>
      a === DEFAULT_PRESET_ID ? -1 : b === DEFAULT_PRESET_ID ? 1 : a.localeCompare(b),
    )
    .map(([id, preset]) => ({
      title: preset.name,
      value: id,
      description: preset.description,
    }));

  if (!hasUserDefault) {
    options.unshift({
      title: DEFAULT_PRESET.name,
      value: DEFAULT_PRESET_ID,
      description: DEFAULT_PRESET.description,
    });
  }

  api.ui.dialog.replace(() => {
    return (
      <PresetPicker
        api={api}
        options={options}
        current={current}
        onSelect={(opt) => {
          const id = opt.value;
          if (session_id) state.setSessionPreset(session_id, id);
          state.setLastPreset(id);
          api.ui.dialog.clear();
        }}
      />
    );
  });
  api.ui.dialog.setSize("xlarge");
}
