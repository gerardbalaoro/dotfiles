// @ts-check
/**
 * Shapes of Claude Code's JSON input, and the defaults merged under it.
 *
 * @typedef {(text: string) => string} Style  Wraps text in styling; '' stays ''.
 *
 * @typedef {object} Window  A usage-limit window (claude.ai subscribers only).
 * @property {number | null} used_percentage
 * @property {number} resets_at  Unix epoch seconds.
 *
 * @typedef {object} SpendLimit  Only behind a Claude apps gateway.
 * @property {number | null} used_percentage
 * @property {number} [used_usd]
 * @property {number} [limit_usd]
 *
 * @typedef {object} StatusInput  JSON on stdin for the main status line, after DEFAULTS.
 * @property {{ id: string, display_name: string }} model
 * @property {{ level: string }} effort
 * @property {string} cwd
 * @property {{ current_dir: string, project_dir: string, git_worktree?: string, repo?: { host?: string, owner?: string, name?: string } }} workspace
 * @property {{ name?: string, branch?: string }} [worktree]
 * @property {{ context_window_size: number, used_percentage: number, remaining_percentage: number, total_input_tokens?: number, total_output_tokens?: number, current_usage?: { input_tokens?: number, output_tokens?: number, cache_creation_input_tokens?: number, cache_read_input_tokens?: number } | null }} context_window
 * @property {{ total_cost_usd: number, total_duration_ms: number }} cost
 * @property {{ five_hour?: Window, seven_day?: Window, spend_limit?: SpendLimit }} rate_limits
 *
 * @typedef {object} Task  One sub-agent row, after TASK_DEFAULTS.
 * @property {string} id
 * @property {string} name
 * @property {string} agentType
 * @property {string} type
 * @property {string} status  running | completed | failed | killed
 * @property {string} description
 * @property {number} startTime  ms since epoch (0 = unknown).
 * @property {string} model  Resolved model ID, e.g. claude-sonnet-5-5.
 * @property {string | number} effort  Configured effort level or token budget; '' = unknown.
 * @property {number} tokenCount
 * @property {number} contextWindowSize  0 = unknown.
 */

/** @type {StatusInput} */
const DEFAULTS = {
  model: { id: '', display_name: '?' },
  effort: { level: '' },
  cwd: '',
  workspace: { current_dir: '', project_dir: '' },
  context_window: { context_window_size: 0, used_percentage: 0, remaining_percentage: 100 },
  cost: { total_cost_usd: 0, total_duration_ms: 0 },
  rate_limits: {},
};

/** @type {Task} */
const TASK_DEFAULTS = {
  id: '', name: '', agentType: '', type: 'agent', status: 'unknown',
  description: '', startTime: 0, model: '', effort: '', tokenCount: 0, contextWindowSize: 0,
};

module.exports = { DEFAULTS, TASK_DEFAULTS };
