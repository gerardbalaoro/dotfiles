import type { TuiPluginApi } from "@opencode-ai/plugin/tui";
import { createEffect, createMemo, createSignal, on, onCleanup } from "solid-js";
import type { Config } from "../config";
import { Metrics } from "../metrics";
import type { Session } from "../metrics";
import { Section } from "./section";

async function loadChildStats(api: TuiPluginApi, rootSessionId: string): Promise<Metrics> {
  const totals = new Metrics();
  const seen = new Set<string>([rootSessionId]);
  const queue: string[] = [rootSessionId];

  while (queue.length) {
    const parentId = queue.shift()!;
    const children = await api.client.session
      .children({ sessionID: parentId })
      .then((res) => res.data ?? [])
      .catch(() => [] as Session[]);

    for (const child of children) {
      if (seen.has(child.id)) continue;
      seen.add(child.id);
      queue.push(child.id);
      totals.add(await Metrics.fromSessionMessages(api, child));
    }
  }

  return totals;
}

export function Tracker(props: { api: TuiPluginApi; config: Config; session_id: string }) {
  const theme = () => props.api.theme.current;
  const cfg = () => props.config;

  const [sessionMetrics, setSessionMetrics] = createSignal<Metrics>(new Metrics());
  const [childMetrics, setChildMetrics] = createSignal<Metrics>(new Metrics());
  const [loading, setLoading] = createSignal(false);

  createEffect(
    on(
      () => [props.session_id, cfg().include_subagents] as const,
      ([sessionId, includeSubagents]) => {
        const session = props.api.state.session.get(sessionId);
        const messages = props.api.state.session.messages(sessionId);
        const localMetrics =
          messages.length > 0
            ? Metrics.fromMessages(messages)
            : session
              ? Metrics.fromSessionRollup(session)
              : undefined;

        setSessionMetrics(localMetrics ?? new Metrics());
        setChildMetrics(new Metrics());
        setLoading(includeSubagents);
      },
    ),
  );

  createEffect(
    on(
      () => [props.session_id, cfg().include_subagents] as const,
      ([sessionId, includeSubagents]) => {
        const sequence = {
          cancelled: false,
          inFlight: false,
          timeout: undefined as ReturnType<typeof setTimeout> | undefined,
        };

        const refresh = async () => {
          if (sequence.cancelled || sequence.inFlight) return;
          sequence.inFlight = true;

          try {
            const [session, children] = await Promise.all([
              (async () => {
                const session = props.api.state.session.get(sessionId);
                if (!session) return new Metrics();
                return Metrics.fromSessionMessages(props.api, session);
              })(),
              includeSubagents
                ? loadChildStats(props.api, sessionId)
                : Promise.resolve(new Metrics()),
            ]);

            if (!sequence.cancelled && sessionId === props.session_id) {
              setSessionMetrics(session);
              setChildMetrics(children);
              setLoading(false);
            }
          } catch {
            if (!sequence.cancelled && sessionId === props.session_id) {
              setLoading(false);
            }
          } finally {
            sequence.inFlight = false;
            if (!sequence.cancelled) {
              sequence.timeout = setTimeout(() => void refresh(), 2000);
            }
          }
        };

        void refresh();

        onCleanup(() => {
          sequence.cancelled = true;
          if (sequence.timeout !== undefined) clearTimeout(sequence.timeout);
        });
      },
    ),
  );

  const data = createMemo(() => {
    const base = sessionMetrics();
    if (!cfg().include_subagents) return base;
    return Metrics.merge(base, childMetrics());
  });

  return (
    <box gap={1}>
      <Section title="Session" metrics={data()} theme={theme} loading={loading()} />
    </box>
  );
}
