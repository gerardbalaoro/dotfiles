import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { resolveModel } from "../src/model-adapter.ts";

const config = {
  path: ".",
  presets: {
    base: { name: "Base", description: "base", model: "provider/model", variant: "balanced" },
    agents: {
      name: "Agents",
      description: "agents",
      model: "provider/base",
      agent: { review: { model: "other/review" } },
    },
  },
} as const;

describe("resolveModel", () => {
  it("applies agent model before preset model and preserves preset variant", () => {
    assert.deepEqual(
      resolveModel(config, "agents", "review", {
        providerID: "old",
        modelID: "old",
        variant: "old",
      }),
      {
        model: { providerID: "other", modelID: "review", variant: "old" },
        preset: "agents",
        routedDefault: false,
      },
    );
  });

  it("falls back to the original model for missing presets", () => {
    assert.deepEqual(
      resolveModel(config, "missing", undefined, { providerID: "old", modelID: "old" }),
      {
        model: { providerID: "old", modelID: "old" },
        preset: "default",
        routedDefault: true,
      },
    );
  });
});
