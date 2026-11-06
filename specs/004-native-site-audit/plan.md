# Implementation Plan: Native site accessibility audit

**Branch**: `codex/woodpecker-plugin-cutover-20261106` | **Date**: 2026-11-06 | **Spec**: [spec.md](spec.md)

## Summary

Add a serial native site workflow while retaining hosted acceptance. Build and test with the existing immutable toolchain. Audit using official Puppeteer/Chrome image25.16.0 pinned by digest and the repository lockfile Lighthouse13.5.0. The Node helper awaits owned HTTP listening, Puppeteer launch, and DevTools metadata before invoking Lighthouse against the owned browser port.

## Technical Context

Node24.21 in the official browser image meets the repository >=24.19 floor. Use built-in HTTP/filesystem APIs, image-provided Puppeteer, and locked Lighthouse. Generated site and npm dependencies live in the checkout workspace; browser profile and reports use owned temporary roots. The image runs as UID10042. Verify actual workspace readability and browser launch without SYS_ADMIN before delivery.

## Constitution Check

Stock-bar, monitor state, motion, and settings contracts are unchanged. Isolated Runtime Evidence applies: no live compositor/device access, owned temporary browser/profile/server, bounded launch timeout, cleanup in finally. The post-design check confirms no host socket, privileged mode, secrets, or desktop mutation.

## Project Structure

`.woodpecker/site.yml` owns serial build/audit. `scripts/audit-site.mjs` owns HTTP and browser lifetime. Existing build and test commands remain authoritative. `TESTING.md` and `RELEASING.md` describe proof and the retained hosted gate.

## Delivery

Review source and immutable manifest provenance, then execute one actual image probe on an authorized worker. Push only after ordinary hooks pass and independent review. Require real native PR and genuine-main proof. Hosted retirement is a later reviewed change after policy agreement.
