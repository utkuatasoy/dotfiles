# Type Check and Fix with Pyrefly

Run `uv run pyrefly check .` to check for type errors and warnings in the codebase.

Your task is to:
1. Execute the pyrefly type checking command
2. Analyze all errors and warnings reported by pyrefly
3. Fix each issue by editing the relevant files
4. Run the check again to verify all issues are resolved
5. Continue until there are no more errors or warnings

For each error/warning:
- Read the file mentioned in the error
- Understand the type issue
- Apply the appropriate fix (add type hints, fix incorrect types, handle Optional types, etc.)
- Use proper Python type hints (from typing import Optional, List, Dict, etc.)

Keep iterating until pyrefly check passes cleanly or all fixable issues are resolved.