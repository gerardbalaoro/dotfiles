// @ts-check
/** Pure input -> output functions. No stdin/stdout here, so tests can call them directly. */
const { DEFAULTS, TASK_DEFAULTS } = require('./types');
const layouts = require('./layouts');

/** @param {unknown} x @returns {x is Record<string, any>} */
const isObject = (x) => typeof x === 'object' && x !== null && !Array.isArray(x);

/**
 * Deep-merge `over` onto `base`: null/undefined in `over` keep the default.
 * @template T
 * @param {T} base
 * @param {any} over
 * @returns {T}
 */
function merge(base, over) {
  if (over == null) return base;
  if (!isObject(base) || !isObject(over)) return over;
  /** @type {Record<string, any>} */
  const out = { ...base };
  for (const key of Object.keys(over)) out[key] = merge(out[key], over[key]);
  return /** @type {T} */ (out);
}

/** Main status line text for Claude Code's JSON (any shape). @param {any} data */
const renderMain = (data) => layouts.main(merge(DEFAULTS, data));

/**
 * Sub-agent rows as JSON lines, "" when there is nothing to say (Claude Code then keeps its
 * default rows). @param {any} data
 */
function renderTasks(data) {
  const tasks = Array.isArray(data?.tasks) ? data.tasks : [];
  const lines = tasks.map((/** @type {any} */ raw) => {
    const t = merge(TASK_DEFAULTS, raw);
    return JSON.stringify({ id: t.id, content: layouts.task(t) });
  });
  return lines.length ? lines.join('\n') + '\n' : '';
}

module.exports = { merge, renderMain, renderTasks };
