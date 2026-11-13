// motion-bench has no data sources: every value is a constant in app.contract.
// `exact new` writes a data module; this one answers nothing.
import type { Answer } from './app.contract.d.ts';

export const answer: Answer = (source) => {
  throw new Error(`motion-bench declares no sources (asked for ${String(source)})`);
};
