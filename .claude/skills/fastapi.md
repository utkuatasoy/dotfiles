---
name: fastapi
description: FastAPI and Python development conventions. Follow these patterns when working with FastAPI projects.
---

# FastAPI Development Conventions

## Key Principles

- Write concise, technical code with accurate Python examples
- Use functional, declarative programming; avoid classes where possible
- Prefer iteration and modularization over code duplication
- Use descriptive variable names with auxiliary verbs (`is_active`, `has_permission`)
- Use lowercase with underscores for directories and files (`routers/user_routes.py`)
- Use the Receive an Object, Return an Object (RORO) pattern

## Python/FastAPI

- Use `def` for pure functions and `async def` for asynchronous operations
- Use type hints for all function signatures
- Prefer Pydantic models over raw dictionaries for input validation
- File structure: exported router, sub-routes, utilities, static content, types
- Use concise, one-line syntax for simple conditional statements

## Error Handling

- Handle errors and edge cases at the beginning of functions
- Use early returns for error conditions to avoid nesting
- Place the happy path last for improved readability
- Avoid unnecessary else statements; use if-return pattern
- Use guard clauses for preconditions and invalid states
- Use `HTTPException` for expected errors

## FastAPI-Specific

- Use Pydantic models for input validation and response schemas
- Use declarative route definitions with clear return type annotations
- Prefer lifespan context managers over `@app.on_event`
- Use middleware for logging, error monitoring, and performance
- Use Pydantic's `BaseModel` for consistent input/output validation
- Rely on FastAPI's dependency injection for state and shared resources

## Performance

- Minimize blocking I/O; use async for database and external API calls
- Implement caching for static and frequently accessed data
- Optimize serialization with Pydantic
- Use lazy loading for large datasets

## Project Structure

```
src/
├── app/
│   ├── main.py           # FastAPI app entry point
│   ├── core/
│   │   ├── config.py     # Settings with pydantic-settings
│   │   └── logger.py     # Logging configuration
│   ├── api/
│   │   └── v1/
│   │       ├── router.py
│   │       └── endpoints/
│   ├── models/           # Pydantic models
│   ├── services/         # Business logic
│   ├── repositories/     # Data access
│   └── middleware/
tests/
├── conftest.py
└── test_*.py
```

## Common Patterns

### Router Definition
```python
router = APIRouter(prefix="/users", tags=["users"])

@router.get("/{user_id}", response_model=UserResponse)
async def get_user(user_id: int, db: Session = Depends(get_db)) -> UserResponse:
    user = await user_service.get(db, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user
```

### Dependency Injection
```python
async def get_current_user(token: str = Depends(oauth2_scheme)) -> User:
    # validate token and return user
    ...

@router.get("/me")
async def get_me(user: User = Depends(get_current_user)) -> User:
    return user
```

### Settings
```python
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    database_url: str
    debug: bool = False

    class Config:
        env_file = ".env"

settings = Settings()
```
