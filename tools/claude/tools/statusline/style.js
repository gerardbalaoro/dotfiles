// @ts-check
/** Colors, text styles and plain formatting helpers. No Claude Code knowledge in here. */

/** @typedef {import('./types').Style} Style */

const WARN = 60; // percent: green -> yellow
const CRIT = 85; // percent: yellow -> red

/** Honors the NO_COLOR convention, read per call so tests can toggle it. */
const colorsOn = () => !process.env.NO_COLOR;

/**
 * @param {number} open
 * @param {number} close
 * @returns {Style}
 */
const ansi = (open, close) => (text) =>
  !text || !colorsOn() ? text : `\x1b[${open}m${text}\x1b[${close}m`;

const format = {
  bold: ansi(1, 22),
  dim: ansi(2, 22),
  italic: ansi(3, 23),
  underline: ansi(4, 24),
};

const color = {
  red: ansi(31, 39),
  green: ansi(32, 39),
  yellow: ansi(33, 39),
  blue: ansi(34, 39),
  magenta: ansi(35, 39),
  cyan: ansi(36, 39),
  gray: ansi(90, 39),
  /** Green below WARN, yellow below CRIT, red above. @param {number} pct @returns {Style} */
  level: (pct) => (pct >= CRIT ? color.red : pct >= WARN ? color.yellow : color.green),
  /** Color for a sub-agent status. @param {string} status @returns {Style} */
  status: (status) =>
    status === 'running' ? color.yellow
      : status === 'completed' ? color.green
      : status === 'failed' || status === 'killed' ? color.red
      : color.gray,
};

const fmt = {
  /** 1200 -> "1.2k" @param {number} n */
  tokens(n) {
    if (n >= 1e6) return Math.floor(n / 1e5) / 10 + 'M';
    if (n >= 1e3) return Math.floor(n / 1e2) / 10 + 'k';
    return String(n);
  },
  /** Seconds -> "45s", "2m05s", "1h07m" @param {number} s */
  duration(s) {
    if (!Number.isFinite(s) || s < 0) return '';
    if (s >= 3600) return `${Math.floor(s / 3600)}h${String(Math.floor((s % 3600) / 60)).padStart(2, '0')}m`;
    if (s >= 60) return `${Math.floor(s / 60)}m${String(s % 60).padStart(2, '0')}s`;
    return `${s}s`;
  },
  /** Epoch seconds -> time left, "2d7h", "2h13m", "9m"; '' if past. @param {number | undefined} epoch */
  until(epoch) {
    const s = Math.floor(Number(epoch) - Date.now() / 1000);
    if (!Number.isFinite(s) || s <= 0) return '';
    const d = Math.floor(s / 86400);
    const h = Math.floor((s % 86400) / 3600);
    const m = Math.floor((s % 3600) / 60);
    if (d > 0) return `${d}d${h}h`;
    if (h > 0) return `${h}h${String(m).padStart(2, '0')}m`;
    return `${Math.max(m, 1)}m`;
  },
  /** @param {number} usd */
  money: (usd) => `$${usd.toFixed(2)}`,
};

/** Join non-empty parts. @param {string[]} parts @param {string} [sep] */
const row = (parts, sep = format.dim(' | ')) => parts.filter(Boolean).join(sep);

module.exports = { format, color, fmt, row };
