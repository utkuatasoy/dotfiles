# Command: Deslop (Remove AI Code Slop)

Review the current branch diff against main and remove AI-generated code slop.

---

## Usage

```bash
/deslop
/deslop --file path/to/file.py
/deslop --dry-run
```

---

## What This Command Does

### 1) Get the Diff Against Main

```bash
git diff main...HEAD
git diff main...HEAD --name-only
```

If no changes, report and exit.

### 2) Analyze Each Changed File

For each modified file, read the full file and identify AI slop:

#### Unnecessary Comments
- Comments stating the obvious
- Comments inconsistent with file style
- Redundant docstrings
- "# TODO: ..." that aren't actionable

#### Excessive Defensive Checks
- Null checks on internal code paths
- Type checks for already-typed parameters
- Redundant validation (already validated upstream)
- Extra try/except that swallow errors unnecessarily

#### Verbose Variable Names
- Overly long names like `user_authentication_token_string`
- Names that repeat context already clear from scope
- Inconsistent with surrounding code style

#### Type Escape Hatches
- Casts to `Any`
- `# type: ignore` without justification
- Overly broad type annotations

#### Over-Engineering
- Helper functions used only once
- Abstractions for single implementations
- Configuration for non-existent requirements
- Backwards-compatibility code for unused features

#### Style Inconsistencies
- Different formatting than the file
- Different patterns than the codebase
- Added docstrings where file doesn't use them

### 3) Clean Up the Slop

For each issue found:
1. Read the surrounding code to understand the style
2. Make minimal, targeted edits
3. Preserve functionality exactly
4. Match existing patterns

**Rules:**
- Never change logic, only remove slop
- Never add new features or refactor beyond slop removal
- Preserve all existing tests
- If unsure, leave it alone

### 4) Verify Changes

After cleanup:

```bash
git diff
```

Review that only slop was removed, no logic changed.

### 5) Report Summary

Output a 1-3 sentence summary of what was changed:

```
Removed 5 obvious comments, simplified 3 variable names, removed 2 redundant null checks in auth_handler.py and user_service.py.
```

---

## Flags

| Flag | Description |
|------|-------------|
| `--file <path>` | Only clean specific file |
| `--dry-run` | Show what would be changed without editing |
| `--verbose` | Show detailed list of each change |

---

## Examples of Slop Removal

### Comments

```python
# Before (slop)
def get_user(id: int) -> User:
    """Get a user by ID."""  # Redundant docstring
    user = db.query(User).get(id)  # Query the database for user
    return user  # Return the user

# After (clean)
def get_user(id: int) -> User:
    return db.query(User).get(id)
```

### Defensive Checks

```python
# Before (slop)
def process_order(order: Order) -> None:
    if order is None:
        raise ValueError("Order cannot be None")
    if not isinstance(order, Order):
        raise TypeError("Expected Order")
    # actual logic...

# After (clean) - internal function, caller validates
def process_order(order: Order) -> None:
    # actual logic...
```

### Variable Names

```python
# Before (slop)
user_authentication_bearer_token = get_auth_token()
database_connection_pool_instance = get_db_pool()

# After (clean)
token = get_auth_token()
pool = get_db_pool()
```

### Type Escapes

```python
# Before (slop)
result: Any = parse_response(data)  # type: ignore

# After (clean)
result: ParsedResponse = parse_response(data)
```

---

## Notes

- This command is non-destructive by default with `--dry-run`
- Always review changes before committing
- Run tests after cleanup to ensure no regression
- When in doubt, leave the code as-is
