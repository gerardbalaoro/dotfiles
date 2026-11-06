// @ts-check
/** Everything about the context window. */
const { color, fmt } = require('./style');

/** @typedef {import('./types').StatusInput} StatusInput */

/** "42k/200k" tokens in context, colored by fullness. @param {StatusInput} i */
function contextUsage(i) {
  const cw = i.context_window;
  const pct = Math.floor(cw.used_percentage);
  const u = cw.current_usage;
  const current = u && typeof u === 'object'
    ? (u.input_tokens || 0) + (u.cache_creation_input_tokens || 0) + (u.cache_read_input_tokens || 0)
    : Math.round((cw.context_window_size * cw.used_percentage) / 100);
  const text = cw.context_window_size
    ? `${fmt.tokens(current)}/${fmt.tokens(cw.context_window_size)}`
    : `${pct}% ctx`;
  return color.level(pct)(text);
}

module.exports = { contextUsage };
