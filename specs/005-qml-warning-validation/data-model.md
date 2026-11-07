# Validation evidence model

- Input identity: owning source revision and file hashes, supported vendor revision, compatibility transformation hashes and exact CI image digest.
- Validation case: existing target inventory, actual module contexts, private strict policy, command, exit code and raw diagnostics.
- Runtime case: isolated fixture inputs, public field/type inventory, before/after values, object identities, readonly failures and permitted child writes.
- Delivery receipt: independently reviewed final head, required checks, normal merge revision and genuine-main result.

State progresses from prepared to diagnosed to accepted only when the relevant
proof passes. Missing setup, unsupported source drift, missing fields or mismatched
runtime results remain failures or explicit gaps. These records contain no user
configuration, secrets, device identities or persistent application data.
