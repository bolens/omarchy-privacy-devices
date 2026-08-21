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

