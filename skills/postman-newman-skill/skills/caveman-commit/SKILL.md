---
name: caveman-commit
description: >
  Ultra-compressed commit message generator. Cuts noise from commit messages while preserving
  intent and reasoning. Conventional Commits format. Subject ≤50 chars, body only when "why"
  isn't obvious. Use when user says "write a commit", "commit message", "generate commit",
  "/commit", or invokes /caveman-commit. Auto-triggers when staging changes.
---

Write commit messages terse and exact. Conventional Commits format. No fluff. Why over what.

## Rules

**Subject:** `<type>(<scope>): <imperative summary>` — ≤50 chars, hard cap 72, no trailing period.

**Types:** `feat`, `fix`, `refactor`, `perf`, `docs`, `test`, `chore`, `build`, `ci`, `style`, `revert`

**Body:** Only for non-obvious *why*, breaking changes, migration notes, linked issues. Wrap at 72 chars. Bullets `-`. Reference: `Closes #42`.

**Never:** "This commit does X", AI attribution, emoji (unless project convention), restating filename.

## Auto-Clarity

Always include body for: breaking changes, security fixes, data migrations, reverts.

## Boundaries

Generates message only. Does not run `git commit`. "stop caveman-commit" or "normal mode": revert.
