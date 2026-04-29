---
name: trd-implement
description: "Implement the code changes described in a TRD (Technical Requirements Document) from Confluence. Use for: implement TRD, code from TRD, build TRD changes, execute TRD, implement plan, code the plan. Reads the TRD from Confluence, generates production Go code following repo conventions, and writes high-coverage unit tests."
argument-hint: "Confluence page URL or page ID of the TRD (e.g. https://bfifinance.atlassian.net/wiki/spaces/BW/pages/XXXXXXX)"
---

# TRD Implement

## Purpose

Read a published TRD from Confluence and implement the described code changes in the `bravo-partnership-service` workspace, following all repo conventions. Write high-coverage unit tests for every change. Never commit or push code.

## Guiding Principles

- **Ask before assuming.** If any part of the TRD is ambiguous or conflicts with existing code, ask the user before writing code.
- **Minimum blast radius.** Only change files described in the TRD Scope. Do not refactor unrelated code.
- **Repo conventions first.** Follow `copilot-instructions.md` and all `.github/instructions/*.md` files that apply to the modified paths.
- **No unit test omission.** Every new function or branch must have at least one test. Target ≥80% line coverage on new code.

---

## Procedure

### Step 1 — Create a Working Branch

Before touching any files:

1. Run `git status` to confirm the workspace is clean (no uncommitted changes).
2. Run `git checkout master && git pull origin master` to ensure the branch is up to date.
3. Derive the branch name from the Jira ticket key in the TRD argument (e.g. `DPS-1937` → `DPS-1937-<short-slug>`). Ask the user to confirm the branch name if the ticket key cannot be extracted.
4. Run `git checkout -b <branch-name>` to create and switch to the new branch.

### Step 2 — Load the TRD

1. Extract the Confluence page ID from the argument (URL or bare ID).
2. Fetch the page using `mcp_com_atlassian_getConfluencePage` with `responseContentFormat: "markdown"`.
3. Parse the following sections from the TRD:
   - **Scope** — what files/packages are in scope
   - **Implementation Approach** — the chosen design
   - **Database Design** (Section 5) — SQL migrations needed
   - **Business Logic** (Section 6) — rules and conditions to implement
   - **Error Handling** (Section 7) — error types, retry/no-retry decisions
   - **Test Scenarios** (Section 8) — Given/When/Then rows to drive test cases

### Step 3 — Explore Existing Code

Before writing any code:
1. Read every in-scope file listed in the TRD Scope section.
2. Read adjacent files that the changes depend on (interfaces, store methods, constants).
3. Read existing test files in the same package to match test style.
4. Read the relevant `.github/instructions/*.md` for the target path.

If a file referenced in the TRD does not exist, ask the user whether to create it or if the path is wrong.

### Step 4 — Clarify Ambiguities

Before writing any code, surface ALL questions at once:
- Any TRD section that contradicts existing code
- Any interface method that needs to be added to an existing `store` or `service` interface
- Any migration file naming convention questions
- Any unclear business rule conditions

Wait for the user's answers before proceeding.

### Step 5 — Implement in Dependency Order

Follow this order to avoid compilation errors:

1. **SQL migration** (if Section 5 requires it)
   - File: `resources/pgsql/migrations/<timestamp>_<slug>.sql`
   - Include both the forward migration and a rollback comment block.

2. **Store interface + implementation** (if new query methods are needed)
   - Add method signature to `internal/store/<domain>_store.go`
   - Implement in `internal/store/pg/<domain>_store.go` using native SQL (no ORM)
   - Follow the existing SQL constant + function pattern in the file

3. **Service layer** (if Section 6 contains business logic in a service)
   - Implement in `internal/service/`
   - Follow `internal-service.instructions.md`

4. **Consumer / handler changes** (the core business logic change)
   - Implement in the file(s) named in the TRD Scope
   - Follow `internal-rabbitmq.instructions.md` or `internal-grpc-handler.instructions.md` as appropriate
   - Add sentinel error variables (e.g. `var ErrXxx = errors.New(...)`) for new error conditions

5. **Wire-up** — update constructor or registration files if new dependencies are introduced

### Step 6 — Write Unit Tests

For each changed file, create or update `<file>_test.go` in the same package.

**Test requirements:**
- Use table-driven tests (`[]struct{ name string; ... }`) for functions with multiple input variants
- Use `testify/assert` and `testify/mock` (check existing test files for the mock library in use)
- Mock all external dependencies (store, service, publisher, client) — do NOT make real DB or HTTP calls
- Cover every branch introduced by the TRD:
  - Happy path (guard passes, proceed)
  - Guard fails → retry path
  - DB error during guard → retry path
  - Max retries exhausted path (if applicable)
  - Existing non-affected paths must not regress (include at least one regression test)
- Each test row in TRD Section 8 must map to at least one test case

**Naming convention:** match the style of existing tests in the package. If no test file exists yet, follow the pattern in `internal/rabbitmq/statustrack/webhookposting/work_consumer_test.go`.

### Step 7 — Validate

After writing all files:
1. Run `go build ./...` mentally — check that all imports are satisfied and interface implementations are complete.
2. Confirm every new exported symbol follows Go naming conventions.
3. Confirm no `fmt.Println`, `log.Print`, or similar logging — use `zlogger` only.
4. Confirm SQL files are placed under `resources/pgsql/migrations/`.

Report a summary of all files created/modified and the test cases written.

---

## Output Format

After completing implementation, output:

```
## Implementation Summary

### Files Modified
- `path/to/file.go` — description of change

### Files Created
- `path/to/file.go` — description
- `resources/pgsql/migrations/xxx.sql` — description

### Test Coverage
| Test File | Test Cases | Scenarios Covered |
|---|---|---|
| path/to/file_test.go | N | list of TRD Section 8 rows covered |

### Open Items
- Any follow-up items or things the user should verify manually
```
