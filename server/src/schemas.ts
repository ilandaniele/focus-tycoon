import { z } from "zod";

export const MAX_BATCH = 100;
const MAX_DELTA = 1_000_000;

const delta = z.number().int().min(-MAX_DELTA).max(MAX_DELTA);

export const transactionSchema = z.strictObject({
  idem_key: z.string().min(1).max(128),
  delta_coins: delta,
  delta_nature: delta,
  delta_xp: z.number().int().min(0).max(MAX_DELTA),
  reason: z.string().min(1).max(32),
  client_at: z.iso.datetime({ precision: 0 }),
});

export const pushSchema = z.strictObject({
  transactions: z.array(transactionSchema).min(1).max(MAX_BATCH),
});

export type Transaction = z.infer<typeof transactionSchema>;
