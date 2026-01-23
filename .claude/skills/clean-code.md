---
name: clean-code
description: Write clean, minimal code without AI slop. Always apply these principles when writing or reviewing code.
---

# Clean Code Principles

Write code like an experienced developer, not like an AI. Avoid common AI code patterns that make code verbose, defensive, or inconsistent.

---

## What to Avoid (AI Slop)

### Unnecessary Comments
- Don't add comments that state the obvious
- Don't add comments a human wouldn't write
- Only comment genuinely complex or non-obvious logic
- Match the comment style of the existing file

```python
# BAD - AI slop
user_id = get_user_id()  # Get the user ID from the request

# GOOD - no comment needed, code is self-explanatory
user_id = get_user_id()
```

### Excessive Defensive Checks
- Don't add null/type checks for trusted internal code paths
- Don't validate inputs that are already validated upstream
- Match the defensive level of surrounding code
- Only validate at system boundaries (user input, external APIs)

```python
# BAD - AI slop (internal function, caller already validated)
def process_user(user: User) -> Result:
    if user is None:
        raise ValueError("User cannot be None")
    if not isinstance(user, User):
        raise TypeError("Expected User instance")
    ...

# GOOD - trust the caller, it's internal code
def process_user(user: User) -> Result:
    ...
```

### Overly Verbose Variable Names
- Use concise, contextually clear names
- Match the naming style of the codebase
- Shorter names are fine when context is clear

```python
# BAD - AI slop
user_authentication_token_string = get_token()
retrieved_database_connection_instance = get_db()

# GOOD
token = get_token()
db = get_db()
```

### Type Escape Hatches
- Don't cast to `Any` to bypass type issues
- Don't use `# type: ignore` without good reason
- Fix the actual type issue instead

```python
# BAD
result: Any = some_function()  # type: ignore

# GOOD - fix the actual type
result: ExpectedType = some_function()
```

### Over-Engineering
- Don't add abstractions for single-use code
- Don't add configuration for hypothetical future needs
- Don't create helper functions for one-time operations
- Three similar lines > premature abstraction

### Inconsistent Style
- Match the existing file's formatting
- Match the existing file's patterns
- Don't "improve" code you're not changing
- Don't add docstrings to files that don't use them

---

## What to Do

1. **Read before writing**: Understand the file's style first
2. **Minimal changes**: Only change what's necessary
3. **Match patterns**: Use the same patterns as existing code
4. **Trust internal code**: Don't over-validate trusted paths
5. **Concise naming**: Short names when context is clear
6. **No unnecessary comments**: Code should be self-documenting
7. **Fix, don't escape**: Solve type issues properly
