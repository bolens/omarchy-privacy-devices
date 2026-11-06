# Data and lifetime model

An audit run owns one HTTP server, one browser and its temporary profile, and one ephemeral report. Startup progresses through listening, browser-ready, DevTools-verified, audited, and closed. Failure at any stage retains nonzero status and enters cleanup. The report must contain an accessibility category with numeric score exactly1. No persistent application state is written.
