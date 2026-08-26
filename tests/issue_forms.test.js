const assert = require("node:assert/strict")
const fs = require("node:fs")
const os = require("node:os")
const path = require("node:path")
const { spawnSync } = require("node:child_process")

const root = path.join(__dirname, "..")
const validator = path.join(root, "scripts", "validate-issue-forms.rb")
const temporary = fs.mkdtempSync(path.join(os.tmpdir(), "privacy-issue-forms-"))
let fixtureNumber = 0

function validate(files) {
  const directory = path.join(temporary, `fixture-${++fixtureNumber}`)
  fs.mkdirSync(directory)
  for (const [name, content] of Object.entries(files)) fs.writeFileSync(path.join(directory, name), content)
  return spawnSync("ruby", [validator], {
    encoding: "utf8",
    env: { ...process.env, ISSUE_TEMPLATE_DIR: directory },
  })
}

try {
  const repository = spawnSync("ruby", [validator], { encoding: "utf8" })
  assert.equal(repository.status, 0, repository.stderr)

  let result = validate({})
  assert.notEqual(result.status, 0)
  assert.match(result.stderr, /no issue forms found/)

  result = validate({
    "config.yml": "blank_issues_enabled: false\n",
    "bug.yml": "name: Bug\ndescription: Report a bug\nbody:\n  - type: input\n    id: version\n    attributes: {label: Version}\n",
  })
  assert.equal(result.status, 0, result.stderr)
  assert.match(result.stdout, /issue forms valid/)

  result = validate({
    "one.yml": "name: Duplicate\ndescription: One\nbody:\n  - type: input\n    id: same\n  - type: textarea\n    id: same\n",
    "two.yml": "name: Duplicate\ndescription: Two\nbody:\n  - type: executable\n    id: 'bad id'\n",
  })
  assert.notEqual(result.status, 0)
  for (const message of ["field ids must be unique", "invalid type", "needs a valid id", "names must be unique"])
    assert.match(result.stderr, new RegExp(message))
} finally {
  fs.rmSync(temporary, { recursive: true, force: true })
}

console.log("issue form validator tests passed")
