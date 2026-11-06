// @ts-check
/** Everything about model IDs: parsing and display names. */

/**
 * "claude-sonnet-5-5-20260101" -> { family: 'sonnet', major: '5', minor: '5' }. Null if unrecognized.
 * The minor is '' for IDs like "claude-opus-5"; a trailing date is not mistaken for a minor.
 * @param {string} id
 * @returns {{ family: string, major: string, minor: string } | null}
 */
function parseModel(id) {
  const m = /(opus|sonnet|haiku|fable)-(\d+)(?:-(\d{1,2})(?!\d))?/i.exec(id || '');
  return m ? { family: m[1].toLowerCase(), major: m[2], minor: m[3] || '' } : null;
}

/** "claude-sonnet-5-5-20260101" -> "Sonnet 5.5"; unknown IDs pass through. @param {string} id */
function modelName(id) {
  const p = parseModel(id);
  if (!p) return id;
  return p.family[0].toUpperCase() + p.family.slice(1) + ' ' + p.major + (p.minor ? '.' + p.minor : '');
}

module.exports = { parseModel, modelName };
