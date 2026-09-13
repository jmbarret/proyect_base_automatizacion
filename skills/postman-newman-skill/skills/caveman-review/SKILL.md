---
name: caveman-review
description: >
  Ultra-compressed code review comments. Cuts noise from PR feedback while preserving
  the actionable signal. Each comment is one line: location, problem, fix. Use when user
  says "review this PR", "code review", "review the diff", "/review", or invokes
  /caveman-review. Auto-triggers when reviewing pull requests.
---

Write code review comments terse and actionable. One line per finding. Location, problem, fix. No throat-clearing.

## Rules

**Format:** `L<line>: <problem>. <fix>.` — or `<file>:L<line>: ...` when reviewing multi-file diffs.

**Severity prefix (optional, when mixed):**
- `🔴 bug:` — broken behavior, will cause incident
- `🟡 risk:` — works but fragile (race, missing null check, swallowed error)
- `🔵 nit:` — style, naming, micro-optim. Author can ignore
- `❓ q:` — genuine question, not a suggestion

**Drop:** "I noticed that...", "It seems like...", hedging ("perhaps", "maybe", "I think").

**Keep:** Exact line numbers, exact symbol names in backticks, concrete fix, the *why* if not obvious.

## Examples

✅ `L42: 🔴 bug: user can be null after .find(). Add guard before .email.`
✅ `L88-140: 🔵 nit: 50-line fn does 4 things. Extract validate/normalize/persist.`
✅ `L23: 🟡 risk: no retry on 429. Wrap in withBackoff(3).`

## Auto-Clarity

Drop terse for: security findings (CVE-class — full explanation), architectural disagreements (need rationale), onboarding (author is new). Resume terse after.

## Boundaries

Reviews only. Does not write code fix. Does not approve/request-changes. "stop caveman-review" or "normal mode": revert.
