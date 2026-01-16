# Test Generator Command

You are a professional backend QA/test automation engineer specializing in FastAPI Python applications with pytest.

**Your task:** Generate comprehensive test suites for the specified source file(s).

---

## Arguments

`$ARGUMENTS` - Path to source file(s) to test (e.g., `app/services/my_service.py` or `app/api/v1/endpoints/`)

---

## Pre-Flight Checks (CRITICAL - Do First!)

Before generating any tests, verify these configuration files exist. **Create them if missing:**

### 1. `tests/conftest.py` - Settings Mock & Path Setup

**IMPORTANT:** Read the project's `app/core/config.py` first to identify required settings, then mock them accordingly.

```python
import sys
from pathlib import Path
from unittest.mock import MagicMock

PROJECT_ROOT = Path(__file__).resolve().parents[1]
SRC_PATH = PROJECT_ROOT / "src"

# Mock settings BEFORE any app imports to avoid Pydantic validation errors
# NOTE: Check app/core/config.py for the actual required settings in this project
mock_settings = MagicMock()

# Example settings - REPLACE with actual settings from app/core/config.py:
# mock_settings.DATABASE_URI = "sqlite:///:memory:"
# mock_settings.API_KEY = "test-key"
# mock_settings.DEBUG = True
# ... add all required settings from the project's config

# Inject mock before imports
sys.modules['app.core.config'] = MagicMock()
sys.modules['app.core.config'].settings = mock_settings

if str(SRC_PATH) not in sys.path:
    sys.path.insert(0, str(SRC_PATH))
```

**Steps to populate mock_settings:**
1. Read `app/core/config.py` or `src/app/core/config.py`
2. Find all required fields in the Settings class (fields without defaults)
3. Add mock values for each required field
4. Optionally mock fields that are used in the code being tested

### 2. `.coveragerc` - Coverage Configuration

```ini
[run]
source = app
relative_files = True
omit =
    */venv/*
    */tests/*

[report]
show_missing = True
#fail_under = 50

[xml]
output = coverage.xml
```

### 3. `pytest.ini` - Pytest Configuration

```ini
[pytest]
markers =
    unit: mark a test as a unit test
    integration: mark a test as an integration test
    slow: marks tests as slow running tests

testpaths = tests
python_files = test_*.py
python_classes = Test*
python_functions = test_*

addopts =
    --verbose
    --tb=short
    --strict-markers
    --cov=app
    --cov-report=term-missing
    --cov-report=xml:coverage.xml
    --junitxml=junit-test-results.xml

filterwarnings =
    ignore::DeprecationWarning
    ignore::UserWarning:pydantic.*
    ignore::sqlalchemy.exc.MovedIn20Warning

log_cli = True
log_cli_level = INFO
log_cli_format = %(asctime)s [%(levelname)8s] %(message)s (%(filename)s:%(lineno)s)
log_cli_date_format = %Y-%m-%d %H:%M:%S

asyncio_mode = auto

env =
    ENVIRONMENT=test
    PYTHONPATH=.
```

### 4. `pyproject.toml` - Dev Dependencies (verify these exist)

```toml
[tool.uv]
dev-dependencies = [
    "pytest>=8.4.2",
    "pytest-asyncio>=0.24.0",
    "pytest-cov>=4.0.0",
]

[tool.pytest.ini_options]
asyncio_mode = "auto"
asyncio_default_fixture_loop_scope = "function"
markers = [
    "unit: marks tests as unit tests",
]
```

---

## Path Mapping Rules

**CRITICAL:** Test files MUST mirror the source structure under `tests/unit/`:

| Source Path | Test Path |
|-------------|-----------|
| `app/services/my_service.py` | `tests/unit/services/test_my_service.py` |
| `app/api/v1/endpoints/chat.py` | `tests/unit/api/v1/endpoints/test_chat.py` |
| `app/core/config.py` | `tests/unit/core/test_config.py` |
| `app/models/user.py` | `tests/unit/models/test_user.py` |
| `app/schemas/intent.py` | `tests/unit/schemas/test_intent.py` |
| `app/repositories/base.py` | `tests/unit/repositories/test_base.py` |

**Naming Convention:**
- Source: `{name}.py` → Test: `test_{name}.py`
- Always prefix test files with `test_`

---

## Test Structure Standards

### File Template

```python
import pytest
from unittest.mock import MagicMock, patch, AsyncMock
from app.{module_path} import {ClassName}


class Test{ClassName}:
    """Test suite for {ClassName}."""

    @pytest.fixture
    def instance(self):
        """Create a testable instance with mocked dependencies."""
        # Bypass __init__ if needed
        obj = {ClassName}.__new__({ClassName})
        obj.dependency = MagicMock()
        return obj

    # --- Method: method_name ---

    @pytest.mark.unit
    def test_method_name_success(self, instance):
        """Test successful execution of method_name."""
        # Arrange
        instance.dependency.some_call.return_value = expected_value

        # Act
        result = instance.method_name(input_data)

        # Assert
        assert result == expected_value

    @pytest.mark.unit
    def test_method_name_failure(self, instance):
        """Test method_name handles errors correctly."""
        instance.dependency.some_call.side_effect = Exception("error")

        with pytest.raises(ExpectedException):
            instance.method_name(input_data)
```

### API Endpoint Template (Direct Function Testing)

**IMPORTANT:** When testing FastAPI endpoint functions directly (not via TestClient), you MUST:
1. Pass explicit values for ALL Header parameters (use `None` or actual strings, NOT Header() objects)
2. Be aware that HTTPExceptions inside try/except blocks may be wrapped in 500 errors

```python
import pytest
from unittest.mock import MagicMock, patch, AsyncMock
from fastapi import HTTPException
from fastapi.responses import StreamingResponse


class TestEndpointName:
    """Test suite for {endpoint_name} endpoints."""

    @pytest.fixture
    def mock_request(self):
        """Create a mock FastAPI request object."""
        request = MagicMock()
        mock_agent = MagicMock()
        mock_graph = MagicMock()
        mock_agent.get_app.return_value = mock_graph
        request.app.state.some_agent = mock_agent
        return request

    @pytest.fixture
    def valid_payload(self):
        """Create a valid request payload."""
        from app.schemas.{schema_module} import {RequestSchema}
        return {RequestSchema}(
            field1="value1",
            field2="value2"
        )

    @pytest.mark.unit
    @pytest.mark.asyncio
    async def test_endpoint_success(self, mock_request, valid_payload):
        """Test successful endpoint response."""
        from app.api.v1.endpoints.{module} import {endpoint_function}

        # Arrange - mock dependencies
        mock_graph = mock_request.app.state.some_agent.get_app.return_value
        mock_state = MagicMock()
        mock_state.next = None
        mock_graph.get_state.return_value = mock_state

        with patch("app.api.v1.endpoints.{module}.SomeService") as mock_service:
            mock_service.return_value.method.return_value = {"result": "success"}

            # Act - IMPORTANT: Pass explicit values for ALL Header params
            response = await {endpoint_function}(
                valid_payload,
                mock_request,
                x_some_header=None,        # NOT Header() object!
                x_another_header="value",  # String or None
            )

            # Assert
            assert response is not None

    @pytest.mark.unit
    @pytest.mark.asyncio
    async def test_endpoint_validation_error(self, mock_request):
        """Test endpoint handles validation errors.

        Note: If the endpoint wraps all exceptions in a generic handler,
        the original error may be wrapped in a 500 response.
        """
        from app.api.v1.endpoints.{module} import {endpoint_function}
        from app.schemas.{schema_module} import {RequestSchema}

        # Arrange - invalid payload
        payload = {RequestSchema}(messages=[])

        # Act & Assert
        with pytest.raises(HTTPException) as exc_info:
            await {endpoint_function}(
                payload,
                mock_request,
                x_header=None  # Explicit None, not Header()
            )

        # Check status code - may be 500 if wrapped by generic handler
        assert exc_info.value.status_code in [400, 500]
        assert "expected error text" in exc_info.value.detail
```

### API Endpoint Template (TestClient - Recommended for Integration)

```python
import pytest
from unittest.mock import MagicMock, patch
from fastapi.testclient import TestClient
from fastapi import status
from app.main import app

client = TestClient(app)


class TestEndpointName:
    """Test suite for {endpoint_name} endpoints."""

    @pytest.fixture(autouse=True)
    def setup(self):
        """Setup dependency overrides."""
        from app.api import deps
        app.dependency_overrides[deps.get_current_user] = lambda: MagicMock()
        app.dependency_overrides[deps.get_db] = lambda: MagicMock()
        yield
        app.dependency_overrides = {}

    @pytest.mark.unit
    @patch("app.services.{service_module}.{ServiceClass}")
    def test_endpoint_success(self, mock_service):
        """Test successful endpoint response."""
        mock_service.return_value.method.return_value = {"id": "123"}

        response = client.post("/api/v1/endpoint", json={"key": "value"})

        assert response.status_code == status.HTTP_200_OK
        assert "id" in response.json()

    @pytest.mark.unit
    def test_endpoint_validation_error(self):
        """Test endpoint returns 422 for invalid input."""
        response = client.post("/api/v1/endpoint", json={})

        assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY
```

---

## Testing Requirements by Module Type

### 1. Services (`app/services/`)
- Mock all external dependencies (LLM, database, other services)
- Test all public methods
- Cover success, failure, and edge cases
- Test exception handling
- Use `@patch` for external calls

### 2. API Endpoints (`app/api/v1/endpoints/`)
- Test all HTTP methods (GET, POST, PUT, DELETE)
- Test authentication/authorization
- Test request validation (422 errors)
- Test success responses (200, 201)
- Test error responses (400, 404, 500)
- Mock service layer completely
- **Pass explicit values for Header params when testing directly**

### 3. Schemas (`app/schemas/`)
- Test Pydantic model validation
- Test default values
- Test field constraints
- Test serialization/deserialization

### 4. Models (`app/models/`)
- Test model instantiation
- Test relationships if any
- Test computed properties

### 5. Core (`app/core/`)
- Test configuration loading
- Test utility functions
- Test constants and enums

### 6. Repositories (`app/repositories/`)
- Use in-memory SQLite from `conftest.py`
- Test CRUD operations
- Test query methods

---

## Quality Standards

1. **Markers:** Always use `@pytest.mark.unit` for unit tests
2. **Docstrings:** Every test must have a clear docstring
3. **AAA Pattern:** Arrange, Act, Assert structure
4. **Independence:** Each test must run in isolation
5. **No Side Effects:** Clean up after tests
6. **Descriptive Names:** `test_{method}_{scenario}_{expected_result}`

---

## Common Pitfalls to Avoid

### 1. Header Parameters in Direct Function Tests
```python
# WRONG - Header() objects don't resolve when calling directly
await endpoint(payload, request, x_header=Header(None))

# CORRECT - Pass actual values
await endpoint(payload, request, x_header=None)
await endpoint(payload, request, x_header="actual-value")
```

### 2. Exception Handling Behavior
If the endpoint wraps all exceptions in a generic try/except:
```python
# The endpoint code:
try:
    if not data:
        raise HTTPException(status_code=400, detail="Missing data")
except Exception as e:
    raise HTTPException(status_code=500, detail=str(e))

# Test should expect 500, not 400
assert exc_info.value.status_code == 500
assert "Missing data" in exc_info.value.detail  # Original message preserved
```

### 3. Missing Settings Mock
Always verify `tests/conftest.py` mocks settings BEFORE any app imports.

---

## Execution Steps

1. **Verify** configuration files exist (conftest.py, .coveragerc, pytest.ini)
2. **Create** missing config files using templates above
3. **Read** the source file(s) specified in `$ARGUMENTS`
4. **Analyze** the module structure, classes, methods, and dependencies
5. **Determine** the correct test file path using the mapping rules
6. **Check** if test file already exists (update vs create)
7. **Generate** comprehensive tests following the templates
8. **Create** necessary `__init__.py` files in test directories
9. **Verify** tests run successfully with `pytest {test_file} -v`

---

## Example Usage

```bash
# Single file
/tester app/services/intent_classifier_service.py

# Directory (all files)
/tester app/services/

# Multiple files
/tester app/services/relevance_service.py app/services/retrieval_service.py
```
