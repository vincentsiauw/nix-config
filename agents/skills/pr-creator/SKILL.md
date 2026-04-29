---
name: pr-creator
description: "Create a GitHub Pull Request for the current branch following the BFI Finance PR description template. Use for: open PR, create PR, raise PR, submit pull request, create pull request. Generates a structured PR description and opens it via GitHub MCP."
argument-hint: "Jira ticket key(s) and brief change description (e.g. DPS-1937 Add DISBURSED ordering guard)"
---

# PR Creator

## Purpose

Create a GitHub Pull Request for the current working branch in the `bfi-finance/bravo-partnership-service` repository. The PR description must follow the standard format established in PR #2078.

## PR Description Template

The PR body must follow this exact structure:

```markdown
## Summary

<1–3 sentences describing WHAT this PR does and WHY. If this PR combines multiple feature PRs or Jira tickets, list each one with a bullet and linked sub-PR.>

Jira: [TICKET-KEY](https://bfifinance.atlassian.net/browse/TICKET-KEY)

---

## Changes

### <Sub-section per logical group, e.g. "Database", "Store Layer", "Service", "gRPC Handler", "RabbitMQ Consumer", "Cron Job">

#### <Sub-sub-section per file or component>
- Bullet describing the change (what was added/modified and why)

---

## Test Plan

- All existing unit tests pass (`go test ./internal/...`)
- Linter clean (`golangci-lint run`) on modified packages
- <Manual test step — specific to the change, e.g. "call X endpoint, verify Y response">

---

## Notes

Unit tests were **not** generated as part of this PR per repository convention. If you'd like relevant unit tests added, they can be added upon request.

<Any other caveats: local replace directives in go.mod, feature flags, migration prerequisites, etc.>
```

---

## Procedure

### Step 1 — Collect Context

1. Run `git branch --show-current` to get the current branch name.
2. Run `git log origin/master..HEAD --oneline` to list commits on this branch.
3. Run `git diff origin/master --stat` to list changed files.
4. If a Jira key is provided in the argument, fetch the ticket via Jira MCP (`mcp_com_atlassian_getJiraIssue`) for title and description.
5. Read changed files (use `git diff origin/master -- <file>` mentally or via `get_changed_files`) to understand the actual code changes.

### Step 2 — Clarify Before Drafting

Ask the user the following if not determinable from context:
- Which Jira ticket(s) does this PR address? (provide key and URL)
- Is this a combination of multiple sub-PRs / feature branches? If yes, list them.
- Target branch: default is `master` — confirm if different.
- Any caveats to include in Notes (e.g. local `go.mod` replace, feature flag, migration required)?

Do NOT proceed to draft until answers are provided.

### Step 3 — Draft PR Description

Fill the template from the **PR Description Template** section above:

1. **Summary**: Write 1–3 sentences. If multiple Jira tickets, list each with a linked sub-PR bullet (see PR #2078 format).
2. **Changes**: Group by layer (Database → Store → Service → Handler/Consumer → Cron → Proto). One sub-section per logical group, one sub-sub-section per file. Use bullet points.
3. **Test Plan**: Always include `go test ./internal/...` and `golangci-lint run`. Add manual verification steps specific to the change.
4. **Notes**: Always include the unit test note. Add any caveats.

### Step 4 — Confirm With User

Present the full draft PR description to the user and ask:
- Does the summary accurately describe the change?
- Are there any missing files or changes to call out in the Changes section?
- Is there anything to add to Test Plan or Notes?

Incorporate feedback before creating.

### Step 5 — Create the PR

Use `mcp_github_create_pull_request` with:
- `owner`: `bfi-finance`
- `repo`: `bravo-partnership-service`
- `title`: `[TICKET-KEY] <short imperative description>` (e.g. `[DPS-1937] Add DISBURSED ordering guard to status track webhook`)
- `body`: the confirmed PR description
- `head`: current branch name (from Step 1)
- `base`: `master` (or confirmed target branch)
- `draft`: `false` unless user requests draft

After creation, output the PR URL for the user.

---

## Output Format

```
## PR Created

**Title**: [DPS-XXXX] ...
**URL**: https://github.com/bfi-finance/bravo-partnership-service/pull/XXXX
**Base**: master ← <branch-name>
**Commits**: N commits, M files changed
```
