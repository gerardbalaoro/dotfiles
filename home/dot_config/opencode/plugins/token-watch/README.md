# OpenCode Token Watch

Renders a live session token usage and cost in the TUI sidebar.
Includes subagents by usage default.

## Installation

1. Add the server entry to `opencode.json`:

   ```json
   {
     "plugin": ["opencode-token-watch/server"]
   }
   ```

2. Add the TUI entry to `tui.json`:

   ```json
   {
     "plugin": ["opencode-token-watch/tui"]
   }
   ```

   Set `include_subagents` to `false` to exclude subagent token usage.

   ```json
   {
     "plugin": [["opencode-token-watch/tui", { "include_subagents": false }]]
   }
   ```

3. Restart OpenCode.

## How It Works

Token Watch reads assistant messages that contain token data and session
rollups. Its data source preference is:

1. HTTP messages
2. Loaded TUI messages
3. Session aggregates

It reports total tokens, input, output, reasoning, cache read/write tokens, and
cost. If OpenCode omits total, Token Watch computes it as input + output +
reasoning; cache tokens remain separate. Values come from OpenCode and provider
integrations. Token Watch does not estimate missing provider prices, change
messages, or persist credentials.

Fallback occurs when a request fails or returns no messages. A non-empty HTTP
response that is silently truncated can still produce incomplete totals. Long
sessions request a high message limit, but server or API limits can cause this.

## Development

These commands are for maintainers working from a source checkout. From this
package directory, allow about 2 minutes for validation:

```sh
npm install
npm run check
npm test
npm pack --dry-run
```

Inspect the dry-run contents before publishing. Publishing remains manual:

```sh
npm publish
```
