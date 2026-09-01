const assert = require("node:assert/strict")
const fs = require("node:fs")

const signature = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10])

function dimensions(file, label = file) {
  const image = fs.readFileSync(file)
  assert.ok(image.length >= 33, `${label} must include a complete IHDR chunk`)
  assert.deepEqual(image.subarray(0, 8), signature, `${label} must have a valid PNG signature`)
  assert.equal(image.readUInt32BE(8), 13, `${label} must use the standard IHDR length`)
  assert.equal(image.subarray(12, 16).toString("ascii"), "IHDR", `${label} must begin with an IHDR chunk`)
  return [image.readUInt32BE(16), image.readUInt32BE(20)]
}

module.exports = { dimensions }
