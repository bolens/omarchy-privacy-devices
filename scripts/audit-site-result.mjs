// Preserve Lighthouse CLI failure semantics when using its programmatic API.
export function requireAccessibleReport(result) {
  if (result?.lhr?.runtimeError)
    throw new Error(`Lighthouse runtime error: ${result.lhr.runtimeError.message || result.lhr.runtimeError.code || 'unknown'}`);
  const score = result?.lhr?.categories?.accessibility?.score;
  if (score !== 1) throw new Error(`Accessibility score must equal 1; received ${score}`);
  return score;
}
