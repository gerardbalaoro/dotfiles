import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { StateStore } from "../src/state.ts";

describe("StateStore", () => {
  it("inherits a parent selection without overwriting it", () => {
    const directory = mkdtempSync(join(tmpdir(), "model-presets-test-"));
    try {
      const store = new StateStore(directory);
      store.setLastPreset("last");
      store.setSessionPreset("parent", "parent-preset");

      assert.equal(store.ensureSessionPreset("child", "parent"), "parent-preset");
      assert.equal(store.ensureSessionPreset("child", "other"), "parent-preset");
    } finally {
      rmSync(directory, { recursive: true, force: true });
    }
  });
});
