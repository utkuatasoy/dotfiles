# Sync Frontend with Backend Changes

Analyze git diff for backend changes and update corresponding frontend files.

---

## Workflow

1. **Get git diff** for backend changes:
   ```bash
   git diff HEAD~1 --stat
   git diff HEAD~1 -- "src/app/api/**/*.py" "src/app/schemas/**/*.py" "src/app/tflow/**/*.py"
   ```

2. **Identify change types**:
   - API endpoint changes (new route, method change, params)
   - Schema changes (new fields, type changes, removed fields)
   - Pipeline node changes (new nodes, renamed nodes)
   - Response format changes

3. **Map to frontend files**:

   | Backend Pattern | Frontend Files |
   |-----------------|----------------|
   | `api/v1/endpoints/test.py` | `static/ui/router/script.js` |
   | `api/v1/endpoints/assist.py` | `static/ui/assist/script.js` |
   | `schemas/agentic_router.py` | `script.js` (response handlers) |
   | `tflow/nodes/**/*.py` | `script.js` (streaming node names) |

4. **Analyze and suggest**:
   - For each affected frontend file, explain what needs to change
   - Show code snippets of current state
   - Suggest specific edits

5. **Apply changes** (with confirmation):
   - Ask user before making edits
   - Show preview of changes
   - Apply using Edit tool

---

## Example

Backend change:
```python
# schemas/agentic_router.py
+ detected_domains: List[str]
- prefilter_candidates: List[IntentCandidate]
```

Frontend update needed:
```javascript
// script.js - line 234
- const candidates = data.prefilter_candidates || [];
+ const domains = data.detected_domains || [];

// Update display logic
- renderCandidatesCard(candidates);
+ renderDomainsCard(domains);
```

---

## Arguments

- `$ARGUMENTS` - Optional: specific file or component to focus on

If no argument provided, analyze all recent backend changes.

---

## Execution Steps

When this skill is invoked:

1. First, run `git diff` to see what changed in the backend
2. Parse the diff to understand:
   - Which files changed
   - What fields/endpoints were added/removed/modified
3. Read the corresponding frontend files
4. Compare backend changes with frontend code
5. Generate specific update suggestions with line numbers
6. Ask user if they want to apply the changes automatically
