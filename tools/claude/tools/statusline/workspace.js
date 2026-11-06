// @ts-check
/** Everything about where we are: the working directory, and its git repo and changes. */
const os = require('os');
const { execFileSync } = require('child_process');
const { format, color } = require('./style');

/** @typedef {import('./types').StatusInput} StatusInput */

/** Run git quietly; '' on any failure. @param {string} dir @param {string[]} args */
function run(dir, args) {
  try {
    return execFileSync('git', ['-C', dir, ...args], {
      encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'], timeout: 2000,
    }).trim();
  } catch {
    return '';
  }
}

/** Working directory with the home folder as ~. @param {StatusInput} i */
function dirShort(i) {
  const dir = i.workspace.current_dir || i.cwd;
  const home = os.homedir();
  return home && dir.startsWith(home) ? '~' + dir.slice(home.length) : dir;
}

/**
 * Git facts for the working directory, or null outside a repo.
 * `added`/`removed` count uncommitted changes to tracked files (git diff HEAD).
 * @param {StatusInput} i
 * @returns {{ repo: string, branch: string, added: number, removed: number } | null}
 */
function git(i) {
  const dir = i.workspace.current_dir || i.cwd;
  if (!dir) return null;
  const top = run(dir, ['rev-parse', '--show-toplevel']);
  if (!top) return null;
  const repo = i.workspace.repo?.name || top.split(/[\\/]/).filter(Boolean).pop() || '';
  const branch = run(dir, ['branch', '--show-current']) || run(dir, ['rev-parse', '--short', 'HEAD']);
  let added = 0;
  let removed = 0;
  for (const line of run(dir, ['diff', '--numstat', 'HEAD']).split('\n')) {
    const [a, r] = line.split('\t'); // binary files show "-"
    added += Number(a) || 0;
    removed += Number(r) || 0;
  }
  return { repo, branch, added, removed };
}

/** "(+10,-4)" for uncommitted changes, '' when clean or not a repo. @param {StatusInput} i */
function diff(i) {
  const g = git(i);
  return g && (g.added || g.removed)
    ? format.dim('(') + color.green(`+${g.added}`) + format.dim(',') + color.red(`-${g.removed}`) + format.dim(')')
    : '';
}

module.exports = { dirShort, git, diff };
