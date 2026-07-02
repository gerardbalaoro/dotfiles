# OpenCode Model Presets

Define reusable model/variant preferences and switch between them at runtime.

## Installation

1. Add the server entry to `opencode.json`:

   ```json
   {
     "plugin": ["opencode-model-presets/server"]
   }
   ```

2. Add the TUI entry to `tui.json`:

   ```json
   {
     "plugin": ["opencode-model-presets/tui"]
   }
   ```

3. Create `~/.config/opencode/opencode.presets.jsonc`:

   ```jsonc
   {
     "openai": {
       "name": "OpenAI",
       "description": "OpenAI models configured to make the most of ChatGPT Plus.",
       // Default model for new sessions and agents
       "model": "openai/gpt-5.6-luna",
       // Default variant of the model
       "variant": "max",
       // Override models for selected agents
       "agent": {
         // Use this model and variant for the explore agent
         "explore": {
           "model": "gpt-5.6-luna",
           "variant": "high",
         },
       },
     },
   }
   ```

4. Restart OpenCode.

Use the `/presets` command to select any preset to apply on the current
or new sessions. A selected preset in a previous session will be retained.

## Preset rules

- A preset requires a `name` and `description`. The `model` and `variant` is optional.
- An `agent` entry requires `model` and may specify `variant`.
- Matching agent variants take precedence in this order: agent variant, preset
  variant, then original variant.
- Preset settings take precedence over OpenCode’s original model and variant.
- A variant-only preset has no effect without a model or matching agent
  override. An agent entry without `variant` inherits the preset variant, then
  the original variant.

Missing or removed presets safely use the original model without deleting the
saved selection.

The plugin does not install models, change provider credentials, or compile its
TypeScript sources. It requires an OpenCode version that supports the exported
TS/TSX files. The config schema is generated and included in the package.

## Development

These commands are for maintainers working from a source checkout. From this
package directory, allow about 2 minutes for validation:

```sh
npm install
npm run build:schema
npm run check
npm test
npm pack --dry-run
```

Inspect the dry-run contents before publishing. Publishing remains manual:

```sh
npm publish
```
