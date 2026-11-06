// @ts-check
/**
 * LAYOUTS: the file to edit to change what the status line looks like.
 *
 * `i` is Claude Code's own JSON (types.js), merged over DEFAULTS so no field is ever missing, so
 * `i.model.display_name` just works. `t` is one sub-agent row. Build with `format`, `color`
 * and `fmt` (style.js), plus the domain modules (context, limits, workspace, task, model). `row()` drops empty pieces, so a helper can return
 * '' to hide itself.
 */
const { format, color, fmt, row } = require('./style');
const { modelName } = require('./model');
const { contextUsage } = require('./context');
const { limit, spend } = require('./limits');
const { dirShort, git: gitInfo, diff } = require('./workspace');
const { taskTokens } = require('./task');

/**
 * @typedef {import('./types').StatusInput} StatusInput
 * @typedef {import('./types').Task} Task
 */

/** @param {StatusInput} i */
// Sonnet 5.5 high | 42k/200k | $1.23 | 5h 24% 7d 71%
// ~/code/app repo:main (+10,-4)
function main(i) {
  const rl = i.rate_limits;
  const git = gitInfo(i);

  const line1 = row([
    row([format.bold(color.cyan(i.model.display_name)), i.effort.level], ' '),
    contextUsage(i),
    fmt.money(i.cost.total_cost_usd),
    row([limit('5h', rl.five_hour), limit('7d', rl.seven_day)], ' '),
    spend(rl.spend_limit),
  ]);

  const line2 = row([
    format.bold(color.blue(dirShort(i))),
    git ? color.magenta(row([git.repo, git.branch], ':')) : '',
    diff(i),
  ], ' ');

  return [line1, line2].filter(Boolean).join('\n');
}

/** @param {Task} t */
// reviewer · Sonnet 5.5 high · 50k tok (25%)
// The name is colored by status (yellow running, green done, red failed).
// Claude Code sends no per-agent cost, so tokens stand in for it.
const task = (t) =>
  row(
    [
      format.bold(color.status(t.status)(t.name || t.agentType || t.type)),
      row([modelName(t.model), String(t.effort)], ' '),
      taskTokens(t),
    ],
    ' · ',
  );

module.exports = { main, task };
