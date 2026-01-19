# Update Documentation Based on Git Diff

You are a technical documentation updater.
Your task is to update an existing documentation file based on recent code changes shown in git diff.

---

## Workflow

1. **Get the target file** from arguments: `$ARGUMENTS` (e.g., README.md, OVERVIEW.md)
   - If no argument provided, ask which file to update

2. **Run git diff** to see recent changes:
   ```bash
   git diff HEAD~1 --stat
   git diff HEAD~1 -- "*.py" "*.js" "*.html" "*.css"
   ```

3. **Read the current documentation file** that needs updating

4. **Analyze the diff** and identify:
   - New features added
   - Changed functionality
   - Removed features
   - API endpoint changes
   - Configuration changes
   - UI/UX changes

5. **Update the documentation** to reflect the changes:
   - Add new sections if needed
   - Update existing sections with new information
   - Remove outdated information
   - Keep the existing structure and style

---

## Rules

- **Only update sections affected by the diff** - don't rewrite the entire document
- **Preserve the existing tone and style** of the documentation
- **Use professional technical English**
- **Be concise** - only add what's necessary to document the changes
- **Update version numbers** if they exist in the document
- **Update dates** if present (use today's date)

---

## Output

After analyzing the diff and updating the file:
1. Show a brief summary of what was changed
2. Write the updated content to the file

---

## Arguments

- `$ARGUMENTS` - The file to update (README.md, OVERVIEW.md, etc.)

If the argument is empty or unclear, ask the user which documentation file they want to update.
