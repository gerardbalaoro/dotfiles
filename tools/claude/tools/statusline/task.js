// @ts-check
/** Everything about one sub-agent row. */
const { format, fmt } = require('./style');

/** @typedef {import('./types').Task} Task */

/** Elapsed time while a sub-agent is running, else ''. @param {Task} t */
const taskElapsed = (t) =>
  t.status === 'running' && t.startTime
    ? format.dim(fmt.duration(Math.floor((Date.now() - t.startTime) / 1000)))
    : '';

/** "50k tok (25%)": tokens, plus context share when known. @param {Task} t */
const taskTokens = (t) =>
  `${fmt.tokens(t.tokenCount)} tok` +
  (t.contextWindowSize ? ` (${Math.floor((t.tokenCount / t.contextWindowSize) * 100)}%)` : '');

module.exports = { taskElapsed, taskTokens };
