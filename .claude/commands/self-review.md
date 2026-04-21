# Self-Review: Analyze and Fix Your Own Code

Perform a rigorous, multi-dimensional review of code you wrote in this session. Identify every issue — security holes, logic bugs, edge cases, naming problems, test gaps — then fix them all.

## Arguments

- `$ARGUMENTS` - (Optional) Specific files, modules, or concerns to focus the review on. If empty, review all code changed in this session.

## Instructions

You are a principal engineer performing a post-implementation self-review. Your job is to adversarially attack your own code: find what breaks, what leaks, what lies, and what's missing. Then fix everything you find.

### Phase 1: Identify the Review Scope

1. Determine which files were created or modified in this session
2. If `$ARGUMENTS` specifies files or focus areas, narrow scope accordingly
3. Read every file in scope — do NOT review from memory, re-read the actual files
4. Read the parent/base classes, interfaces, and callers that interact with the changed code

### Phase 2: Analyze for Issues

Evaluate the code against every category below. For each category, explicitly state whether issues were found or not. Do not skip categories.

**Security**
- Can any input bypass authorization or authentication checks?
- Can a client tamper with fields they shouldn't control (IDs, ownership, roles, timestamps)?
- Are there injection vectors (SQL, command, XSS, log injection)?
- Does the code leak information through error messages, timing, or response differences?
- Are there TOCTOU (time-of-check-to-time-of-use) race conditions between validation and action?

**Correctness & Logic**
- Do all code paths produce the correct result, including null, empty, and boundary inputs?
- Are there off-by-one errors in length checks, pagination, or loops?
- Does the code handle concurrent access correctly (shared mutable state, non-atomic operations)?
- Are exceptions caught at the right level — not swallowed, not leaking implementation details?
- Does the override/inheritance interact correctly with the base class (calling super at the right time, not breaking invariants)?

**Edge Cases & Robustness**
- What happens with null, empty string, whitespace-only, max-length, and just-over-max-length inputs?
- What happens when the database returns no rows, one row, or many rows?
- What happens when the security context is missing, expired, or contains an unexpected principal type?
- What happens on duplicate requests (idempotency)?

**Data Integrity**
- Are audit fields (createdBy, updatedBy, ownerId, timestamps) always set correctly and never overwritable by clients?
- Can soft-deleted records leak into query results?
- Can a record's ownership or status be changed through unprotected paths?

**API Contract & Integration**
- Does the code honor the interface contract (return types, exception types, nullability)?
- Are HTTP status codes correct for each error case (400 vs 401 vs 403 vs 404)?
- Does the code interact correctly with the framework's lifecycle (hooks called in the right order, transactional boundaries respected)?

**Performance**
- Are there redundant database queries (N+1, duplicate lookups for the same record)?
- Are there unbounded queries that could return millions of rows?
- Is there unnecessary object allocation in hot paths?

**Test Quality**
- Does every behavioral path in the production code have a corresponding test?
- Do test names accurately describe what they verify?
- Are there tests that pass for the wrong reason (e.g., testing the mock instead of the logic)?
- Are there unused test fields, dead test code, or copy-paste artifacts?
- Are negative cases tested (unauthorized access, invalid input, not-found)?
- Do tests verify the actual saved/returned values, not just that no exception was thrown?

### Phase 3: Classify Issues

Classify every issue found into exactly one severity:

- **CRITICAL** — Security vulnerability, data corruption, or silent wrong behavior in production
- **MAJOR** — Incorrect behavior under realistic conditions, missing validation, or logic error that will eventually be hit
- **MINOR** — Misleading names, redundant code, missing edge-case tests, style inconsistency, or performance waste that doesn't affect correctness

### Phase 4: Fix

1. Fix all CRITICAL and MAJOR issues immediately by editing the production code
2. Fix all MINOR issues in tests and naming
3. For issues that require changes outside the current scope (e.g., modifying a shared base class), document them clearly as **ACKNOWLEDGED — Out of Scope** with a precise explanation of the risk and the recommended fix
4. After all fixes, re-run the full test suite to verify nothing is broken
5. If any fix introduces a new behavioral path, add a test for it

### Phase 5: Report

Present a clear summary table to the user:

| # | Severity | Category | Issue | Fix Applied |
|---|----------|----------|-------|-------------|

End with:
- Total issues found (by severity)
- Total issues fixed vs. acknowledged
- Confirmation that tests pass

## Strict Rules

1. NEVER review from memory — always re-read the actual files before analyzing
2. NEVER dismiss an issue as "unlikely" — if it's possible, report it
3. NEVER fix an issue without a test that covers the fix (unless it's a pure naming/style change)
4. NEVER change code outside the review scope without explicitly stating why
5. If you find zero issues in any category, explicitly state "No issues found" — do not silently skip it
6. Always run the full test suite after fixes, not just the changed tests
