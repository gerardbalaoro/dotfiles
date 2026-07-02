import { z } from "zod";

export const ConfigSchema = z
  .object({
    include_subagents: z.boolean().optional().default(true),
  })
  .strict();

export type Config = z.infer<typeof ConfigSchema>;
