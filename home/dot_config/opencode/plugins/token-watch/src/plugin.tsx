import type { TuiPlugin, TuiPluginModule } from "@opencode-ai/plugin/tui";
import { ConfigSchema } from "./config";
import { Tracker } from "./components/tracker";

const tui: TuiPlugin = async (api, options) => {
  const config = ConfigSchema.parse(options ?? {});

  api.slots.register({
    order: 150,
    slots: {
      sidebar_content(_ctx, props: { session_id: string }) {
        return <Tracker api={api} session_id={props.session_id} config={config} />;
      },
    },
  });
};

export default { id: "token-watch", tui } satisfies TuiPluginModule;
