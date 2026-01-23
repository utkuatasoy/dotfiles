# FastAPI Development Rules

## Key Principles

- Write concise, technical responses with accurate Python examples.
- Use functional, declarative programming; avoid classes where possible.
- Prefer iteration and modularization over code duplication.
- Use descriptive variable names with auxiliary verbs (e.g., `is_active`, `has_permission`).
- Use lowercase with underscores for directories and files (e.g., `routers/user_routes.py`).
- Favor named exports for routes and utility functions.
- Use the Receive an Object, Return an Object (RORO) pattern.

## Python/FastAPI

- Use `def` for pure functions and `async def` for asynchronous operations.
- Use type hints for all function signatures.
- Prefer Pydantic models over raw dictionaries for input validation.
- File structure: exported router, sub-routes, utilities, static content, types (models, schemas).
- Use concise, one-line syntax for simple conditional statements.

## Error Handling

- Handle errors and edge cases at the beginning of functions.
- Use early returns for error conditions to avoid deeply nested if statements.
- Place the happy path last in the function for improved readability.
- Avoid unnecessary else statements; use the if-return pattern instead.
- Use guard clauses to handle preconditions and invalid states early.
- Implement proper error logging and user-friendly error messages.

## FastAPI-Specific Guidelines

- Use Pydantic models for input validation and response schemas.
- Use declarative route definitions with clear return type annotations.
- Prefer lifespan context managers over `@app.on_event("startup")` and `@app.on_event("shutdown")`.
- Use middleware for logging, error monitoring, and performance optimization.
- Use `HTTPException` for expected errors.
- Use Pydantic's `BaseModel` for consistent input/output validation.

## Performance

- Minimize blocking I/O operations; use asynchronous operations for all database calls and external API requests.
- Implement caching for static and frequently accessed data using Redis or in-memory stores.
- Optimize data serialization and deserialization with Pydantic.
- Use lazy loading techniques for large datasets.

## Key Conventions

1. Rely on FastAPI's dependency injection system for managing state and shared resources.
2. Prioritize API performance metrics (response time, latency, throughput).
3. Favor asynchronous and non-blocking flows.
4. Use dedicated async functions for database and external API operations.
