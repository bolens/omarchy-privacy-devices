const assert = require('node:assert/strict');

(async () => {
  const { requireAccessibleReport } = await import('../scripts/audit-site-result.mjs');
  const report = score => ({ lhr: { categories: { accessibility: { score } } } });
  assert.equal(requireAccessibleReport(report(1)), 1);
  for (const score of [0.99, 0, null, '1', undefined])
    assert.throws(() => requireAccessibleReport(report(score)), /score must equal 1/);
  assert.throws(() => requireAccessibleReport(undefined), /score must equal 1/);
  const partial = report(1);
  partial.lhr.runtimeError = { code: 'NO_FCP', message: 'Page did not render' };
  assert.throws(() => requireAccessibleReport(partial), /Lighthouse runtime error: Page did not render/,
    'A partial perfect category must never hide a Lighthouse runtime failure');
  console.log('Native accessibility report acceptance passed');
})().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
