// @ts-check
/**
 * Claude Code status line + sub-agent status line. Entry point: reads stdin, prints.
 *
 *   main line:       node -e "require(require('os').homedir()+'/.claude/tools/statusline')"
 *   sub-agent rows:  node -e "require(require('os').homedir()+'/.claude/tools/statusline')" subagent
 *
 * Cross-platform (Linux, macOS, Windows). Needs only Node.js; git is optional.
 *
 * Layout: layouts.js is what you edit. Each other file owns one domain and everything about it:
 *   context.js  limits.js  workspace.js (dir, git)  task.js  model.js
 *   style.js (colors, formats)  types.js (input shapes, defaults)
 *   render.js (input -> output, pure)  test.js (`node --test`)
 */
const { renderMain, renderTasks } = require('./render');

const mode = process.argv[process.argv.length - 1] === 'subagent' ? 'subagent' : 'main';

let raw = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', (chunk) => { raw += chunk; });
process.stdin.on('end', () => {
  /** @type {any} */
  let data = {};
  try { data = JSON.parse(raw); } catch { /* fall through to defaults */ }
  process.stdout.write(mode === 'subagent' ? renderTasks(data) : renderMain(data));
});
