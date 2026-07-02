import { writeFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

import { z } from "zod";

import { ConfigSchema } from "../src/config.js";

const here = dirname(fileURLToPath(import.meta.url));
const outPath = resolve(here, "..", "config.schema.json");

const schema = z.toJSONSchema(ConfigSchema, { target: "draft-2020-12" });

// Permit a top-level `$schema` pointer (string) so editor tooling can
// reference this file without altering the Preset-valued
// `additionalProperties` semantics produced from ConfigSchema. Because
// `$schema` is now listed in `properties`, it is exempt from
// `additionalProperties` (which still requires Preset values for every
// other string-named property).
schema.properties = {
  ...schema.properties,
  $schema: { type: "string" },
};

const json = JSON.stringify(schema, null, 2) + "\n";

writeFileSync(outPath, json, "utf8");
console.log(`wrote ${outPath}`);
