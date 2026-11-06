// @ts-check
/** Everything about usage limits: the 5h/7d windows and the gateway spend limit. */
const { color, fmt } = require('./style');

/**
 * @typedef {import('./types').Window} Window
 * @typedef {import('./types').SpendLimit} SpendLimit
 */

/** "5h 24%", or '' when the window is absent. @param {string} label @param {Window | undefined} win */
function limit(label, win) {
  if (win?.used_percentage == null) return '';
  const pct = Math.round(win.used_percentage);
  return `${label} ${color.level(pct)(`${pct}%`)}`;
}

/** "2h13m" until a limit window resets, or ''. @param {Window | undefined} win */
const resetIn = (win) => fmt.until(win?.resets_at);

/** Gateway spend limit, or ''. @param {SpendLimit | undefined} s */
function spend(s) {
  if (s?.used_percentage == null) return '';
  const text = s.used_usd != null && s.limit_usd != null
    ? `$${Math.round(s.used_usd)}/$${Math.round(s.limit_usd)}`
    : `${Math.round(s.used_percentage)}%`;
  return `spend ${color.level(s.used_percentage)(text)}`;
}

module.exports = { limit, resetIn, spend };
