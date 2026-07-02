import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { Metrics } from "../src/metrics.ts";

describe("Metrics", () => {
  it("aggregates assistant token and cost fields", () => {
    const metrics = Metrics.fromMessages([
      {
        role: "assistant",
        cost: 1.25,
        tokens: { input: 10, output: 20, reasoning: 3, total: 33, cache: { read: 4, write: 5 } },
      },
      { role: "user" },
      { role: "assistant", cost: 0.75, tokens: { input: 2, output: 4, reasoning: 1, cache: {} } },
    ] as never);
    assert.equal(metrics.cost, 2);
    assert.deepEqual(metrics.tokens, {
      input: 12,
      output: 24,
      reasoning: 4,
      cache_read: 4,
      cache_write: 5,
      total: 40,
    });
  });
});
