# Security policy

## Supported versions

Security fixes are provided for the latest released version. Update the plugin
before reporting a vulnerability or testing a fix.

## Reporting a vulnerability

Do not open a public issue for vulnerabilities, unsafe privilege boundaries,
command injection, process-identity problems, or information disclosure.

Use [GitHub private vulnerability reporting](https://github.com/bolens/omarchy-privacy-devices/security/advisories/new)
and include:

- The affected plugin and Omarchy versions.
- The control, backend, or script involved.
- Reproduction steps and expected security boundary.
- Impact and prerequisites.
- A minimal proof of concept, if safe to share privately.

Remove secrets, usernames, device serials, and unrelated personal information.
You should receive an initial response within seven days. Please allow time to
investigate and publish a coordinated fix before public disclosure.

## Scope

The plugin deliberately runs local control helpers and user-configured custom
commands. A report is in scope when the plugin crosses its documented privilege,
process-identity, path, or data-handling boundaries. Risks inherent to a custom
command explicitly supplied by the user are not vulnerabilities in the plugin.

## Trust boundaries

- Activity metadata and process names are untrusted text. The UI renders them
  as plain text, notifications pass them as separate process arguments, and
  private diagnostics redact application and device identities by default.
  Control characters and Unicode direction overrides are removed before
  metadata is displayed or persisted.
- Only the fixed camera and GeoClue controls cross a privilege boundary. They
  use Polkit with allowlisted system paths and never interpolate settings into
  privileged commands.
- Recorder shutdown is limited to an owner-matched PID whose `/proc` executable
  is `wf-recorder`; broad name-based termination is forbidden.
- History and settings exports are size-bounded, atomically replaced, and
  stored in owner-only user directories. They contain no media. Device policy
  names and aliases are bounded settings metadata and may identify local
  hardware, so exported settings should be treated as private.
- Privacy lockdown uses the same verified, allowlisted per-device controls as
  individual actions. It applies them serially, reports partial failures, and
  keeps its observed-state undo only in memory for 30 seconds.
- Custom screenshot and recording commands are an explicit user-controlled
  escape hatch. Imported settings must be reviewed before those backends are
  selected or run.
- Built-in capture helpers and Omarchy commands use argument arrays and never
  inherit the custom-command shell-string boundary.
- Notification and launcher actions enter through an allowlisted helper. Their
  commands never contain observed application, process, or device text.
- The optional menu installer atomically edits only its marked block, preserves
  existing entries, and routes lockdown through the UI's two-step confirmation.
- Observer alerts expose only bounded source/code identifiers. Guided self-test
  and copied results omit session identities and inspect history permissions
  without exposing its filesystem path.

## Release security checklist

Before tagging a release:

1. Run the full matrix in [TESTING.md](TESTING.md), including
   `tests/security.test.js`.
2. Review new process launches for argument separation and allowlisted values.
3. Review new file writes for bounded input, private permissions, and atomic
   replacement.
4. Confirm privileged commands use fixed absolute executables and fixed
   resources; settings must never enter a privileged command.
5. Confirm GitHub Actions remain SHA-pinned with least-privilege permissions.
6. Inspect the clean `git archive` used for release and scan tracked files for
   credentials, private diagnostics, generated output, and dependency trees.
7. Audit site-tooling dependencies and resolve production-impacting findings.

## Related documentation

See the [documentation index](DOCUMENTATION.md), documented runtime
[security boundaries](ARCHITECTURE.md#security-boundaries), and private-report
[support guidance](SUPPORT.md).
