# Clean Python cache directories

This command finds and removes all `__pycache__` directories recursively from the current directory, which store Python bytecode compilation artifacts.

```bash
find . -type d -name "__pycache__" -exec rm -rf {} +
```