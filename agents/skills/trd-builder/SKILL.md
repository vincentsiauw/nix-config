---
name: trd-builder
description: "Build a Technical Requirements Document (TRD) following the BFI Finance TRD Implementation Template. Use for: writing TRD, creating TRD, generate TRD, technical requirements document, implementation doc, engineer TRD, TRD construction. Outputs a Confluence page in the Technology Development space. Audience: engineers + product/QA."
argument-hint: "Feature name or Jira ticket (e.g. DPS-1234 Add payment webhook)"
---

# TRD Builder

## Purpose

Generate a complete, standard-compliant TRD as a Confluence page under the BFI Finance Technology Development space, following the [TRD Implementation Template](https://bfifinance.atlassian.net/wiki/spaces/TD/pages/2341109934).

## Guiding Principle

Every section exists only if it helps the audience understand the approach. If a section is not applicable, omit it — never leave placeholder text in the published page.

---

## Procedure

### Step 1 — Gather Context

Collect the following before drafting:

1. **Jira ticket(s)**: story or task key(s) — used for Document Information and traceability.
2. **Feature description**: what the implementation does (2–4 sentences).
3. **Scope**: what is in and out of scope.
4. **Services involved**: list service names for the sequence diagram.
5. **API changes** (if any): method, path, request/response shape.
6. **DB changes** (if any): new tables, columns, indexes, migrations.
7. **Business rules** (if any): validation, state transitions, computations.
8. **Target Confluence parent page**: ask the user if not obvious.

Use the Jira MCP tool to read the ticket for requirements. Use existing code in the workspace (store/, httpserver/handler/, temporal/workflow/) to confirm implementation details.

### Step 2 — Draft the TRD in Markdown

Follow the section order below. Mark sections `[Required]` or `[Optional — include if applicable]`.

```
Document Information       [Required]
Version History            [Required]
1. Scope                   [Required]
2. Implementation Approach [Required]
3. Sequence / Flow Diagram [Required]
4. API Contract            [Required if API is involved]
5. Database Design         [Required if DB changes involved]
6. Business Logic          [Required if business rules exist]
7. Error Handling & Retry  [Required]
8. Test Scenarios          [Required]
9. Error Code Registry     [Required if custom error codes]
10. Rollback Plan          [Required]
11. Dependencies & Assumptions [Required]
```

### Step 3 — Section Specifications

#### Document Information

| Field | Fill From |
|---|---|
| Squad | Ask user or infer from repo/Jira |
| Author (SE) | Ask user |
| SA Reviewer | Ask user or leave blank |
| Related Story/Task | Jira key with link |
| Related [TRD Architecture] | Ask user if there is an SA-level TRD |
| Related PR | Fill after PR is opened, or leave blank |
| Status | Default: `Draft` |
| Created | Today's date |
| Last Updated | Today's date |

#### 1. Scope

Two-column table: In Scope / Out of Scope. Be specific — name the endpoints, tables, events involved.

#### 2. Implementation Approach

- **Chosen approach**: 2–4 sentences describing the design decision.
- **Alternatives considered**: table with alternative + reason rejected. Include at least one alternative unless there is genuinely only one option.

#### 3. Sequence / Flow Diagram

Use a Mermaid `sequenceDiagram` block with real service names (e.g. `APIGateway`, `DocumentHubService`, `TemporalWorker`, `PostgreSQL`, `RabbitMQ`). Never use generic labels like "Backend".

#### 4. API Contract

One sub-section per endpoint:
- **4.1 Endpoint Definition**: method, path, auth, content-type.
- **4.2 Request Schema**: table with field, type, required, validation rule.
- **4.3 Response Schema**: success payload + error table referencing Section 9.
- **4.4 Example Request & Response**: JSON code blocks.

#### 5. Database Design

- **5.1 Table Definition**: one table per sub-section. Include all columns with type, nullable, default, key, notes.
- **5.2 Index Design**: index name, columns, type (BTREE/HASH), justification tied to a query pattern.
- **5.3 Migration Notes**: migration SQL summary, rollback SQL, data backfill if needed.

#### 6. Business Logic Specification

- **6.1 Rule Registry**: table of all rules with name (kebab-case), type, trigger, owner service.
  - Rule types: Validation | Computation | Trigger | Constraint | State Transition
- **6.2 Rule Definition Blocks**: one block per rule with INPUTS, CONDITIONS (IF/THEN), OUTPUTS, CONSTRAINTS, NOTES.
- **6.3 Decision Tables**: only when a rule has multiple intersecting conditions.
- **6.4 State Transition Table**: required when an entity has a status/lifecycle field. Include guard conditions.

#### 7. Error Handling & Retry

Table with: Scenario | Handling Strategy. Always cover: validation failure (422), external timeout, DB write failure, unexpected exception (500).

#### 8. Test Scenarios

Given/When/Then table. Every rule definition block and every decision table row maps to at least one row here.

#### 9. Error Code Registry

Table: Error Code | HTTP Status | Message (EN) | Retryable | Rule Reference.
Error codes must be unique within this document.

#### 10. Rollback Plan

Table: Rollback Trigger | Rollback Steps | Estimated Time | Data Impact.

#### 11. Dependencies & Assumptions

Two lists:
- **Dependencies**: things that must be true/deployed for this to work.
- **Assumptions**: things assumed true that could invalidate the design if wrong.

---

### Step 4 — Publish to Confluence

Use the `mcp_com_atlassian_createConfluencePage` tool with:
- `cloudId`: `bfifinance.atlassian.net`
- `spaceId`: ask user for the target space ID, or search for "Technology Development" space
- `contentFormat`: `markdown`
- `status`: `draft` (let the author review before publishing)
- `title`: `[TRD Implementation] <Feature Name>`
- `parentId`: ask user for the parent page ID

After creation, return the Confluence page URL to the user.

---

## Quality Checklist (Before Publishing)

- [ ] No placeholder text (`<value>`, `<describe>`) remains in the output
- [ ] All required sections are present
- [ ] Sequence diagram uses real service names
- [ ] Every API field has a validation rule
- [ ] Every rule in Section 6 has at least one test row in Section 8
- [ ] Error codes in Section 4.3 reference entries in Section 9
- [ ] Rollback plan has a concrete trigger condition

---

## References

- [TRD Implementation Template (Confluence)](https://bfifinance.atlassian.net/wiki/spaces/TD/pages/2341109934)
- [TRD Standardization Guideline](https://bfifinance.atlassian.net/wiki/spaces/EA/pages/2341666841)
