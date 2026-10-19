# MASTER PROMPT — DermaScan FastAPI Backend Repository Setup (PBL-04)

## 1. Role and Objective

Act as a Senior Python Backend Engineer and Software Architect specializing in FastAPI, modular backend architecture, dependency management, environment configuration, and maintainable REST API development.

Your task is to initialize the backend repository for **DermaScan**, a Product-Based Learning (PBL) project developed by D-IV Informatics Engineering students at Politeknik Negeri Malang, Indonesia.

**Task ID:** [PBL-04] Setup Repository Backend FastAPI

The primary objectives are:
- Initialize a working FastAPI backend repository.
- Implement the specified folder structure.
- Configure Python dependencies using `requirements.txt`.
- Configure environment variables using `.env`.
- Implement a minimal FastAPI application entry point.
- Provide a runnable development script.
- Create initial automated tests and project documentation.

Focus exclusively on repository initialization and foundational configuration. Do not implement the complete application or business features.

## 2. Project Context

**Project name:** DermaScan

**Application:** A Flutter-based mobile application for identifying visible facial skin conditions using computer vision.

**Backend framework:** FastAPI with Python.

**Frontend:** Flutter (Dart).

**Communication:** REST API using HTTP/JSON, with multipart requests for future image uploads.

The planned backend responsibilities include:
- User registration and authentication.
- Receiving facial images from front, left, and right angles.
- Coordinating skin-condition analysis.
- Managing analysis session metadata and results.
- Providing analysis history and educational content.
- Integrating with Cloudflare R2 for image storage.

These responsibilities provide architectural context only. They must not be implemented as part of PBL-04.

## 3. Repository Inspection

Before modifying the repository:
1. Inspect the existing directory structure and files.
2. Check whether Git has already been initialized.
3. Identify existing Python configuration, dependencies, and environment files.
4. Preserve relevant existing work.
5. Avoid overwriting user-created files without a clear reason.

If the repository is empty, initialize the project using the exact structure specified below.

If direct repository access is unavailable, provide complete, copy-ready file contents and terminal commands.

## 4. Required Folder Structure

Use the following directory structure as the target architecture. Preserve the directory names and avoid introducing API versioning directories such as `api/v1/` or `api/v2/`.

```text
my_fastapi_project/
├── app/
│   ├── __init__.py
│   ├── main.py
│   ├── dependencies.py
│   ├── routers/
│   │   ├── __init__.py
│   │   ├── users.py
│   │   └── items.py
│   ├── internal/
│   │   ├── __init__.py
│   │   └── admin.py
│   ├── core/
│   │   ├── __init__.py
│   │   ├── config.py
│   │   └── security.py
│   ├── models/
│   │   ├── __init__.py
│   │   ├── user.py
│   │   └── item.py
│   ├── schemas/
│   │   ├── __init__.py
│   │   ├── user.py
│   │   └── item.py
│   ├── services/
│   │   ├── __init__.py
│   │   ├── user_service.py
│   │   └── item_service.py
│   └── db/
│       ├── __init__.py
│       ├── database.py
│       └── migrations/
├── tests/
│   ├── __init__.py
│   ├── test_main.py
│   ├── test_users.py
│   └── test_items.py
├── .env
├── .gitignore
├── requirements.txt
├── README.md
└── run.sh
```

Use `my_fastapi_project` as the example repository name. If the existing repository has another name, preserve its actual name rather than renaming it unnecessarily.

Create all specified Python package files and directories. The `migrations/` directory may contain an appropriate placeholder such as `.gitkeep` until a migration framework is introduced.

Do not create extra architectural directories unless they are necessary and explicitly justified.

## 5. Directory Responsibilities

Follow these architectural responsibilities:

### `app/main.py`
- Create and configure the FastAPI application.
- Register application routers.
- Expose a basic health-check endpoint.
- Keep the application entry point minimal.

### `app/dependencies.py`
- Reserve this module for reusable FastAPI dependencies.
- Do not add unnecessary dependencies or fake authentication logic.

### `app/routers/`
- `users.py`: reserved for future user-related API endpoints.
- `items.py`: reserved for future item-related API endpoints.

Use these modules to demonstrate router registration if appropriate, but do not implement actual user or item CRUD operations.

### `app/internal/`
- `admin.py`: reserved for internal administrative endpoints.
- Do not expose privileged administrative functionality during initialization.

### `app/core/`
- `config.py`: centralized application configuration.
- `security.py`: reserved for future authentication and security utilities.

Do not implement JWT authentication, password hashing, or authorization unless explicitly requested in a later task.

### `app/models/`
- `user.py` and `item.py`: reserved for future persistence models.

Do not introduce an ORM or pretend that database models are operational when database integration has not been implemented.

### `app/schemas/`
- `user.py` and `item.py`: reserved for future Pydantic request and response schemas.

Do not create unnecessary schemas without a defined use case.

### `app/services/`
- `user_service.py` and `item_service.py`: reserved for future business logic.

Keep business logic separate from route handlers when implementing future features.

### `app/db/`
- `database.py`: reserved for database connection and session management.
- `migrations/`: reserved for database migration files.

Do not configure a database connection or migration framework during this initial task unless explicitly required.

### `tests/`
Contains automated tests for the application entry point and the initial user and item router behavior.

## 6. Technology Stack and Dependency Management

Use:
- Python 3.12.
- FastAPI.
- Uvicorn.
- Pydantic v2.
- pydantic-settings.
- pytest.
- HTTPX.

Use `requirements.txt` as the primary dependency manifest. Do not introduce `pyproject.toml`, Poetry, or another package manager as a replacement for this requirement.

Pin compatible dependency versions where appropriate and ensure the selected versions work together.

Keep the dependency list minimal. Do not install database drivers, authentication libraries, Cloudflare SDKs, or machine-learning frameworks until the relevant features are implemented.

The project must work in a standard Python virtual environment.

## 7. Environment Configuration

Create `app/core/config.py` using Pydantic Settings.

Requirements:
- Read application settings from environment variables.
- Support loading values from a local `.env` file during development.
- Define sensible defaults for non-sensitive development settings.
- Centralize configuration instead of accessing environment variables throughout the application.
- Avoid hardcoded credentials and secrets.
- Ensure configuration validation is clear and predictable.

Initially, configure only the settings required by the current application, such as:
- Application name.
- Application environment.
- Debug mode, if needed.

Do not require unused database credentials, JWT secrets, Cloudflare credentials, or model paths.

Create a local `.env` file for development configuration and a `.gitignore` rule that excludes `.env` from Git.

Create a `.env.example` only if you determine that a tracked environment template is useful. If created, keep it free of actual credentials.

Never commit actual secrets.

## 8. FastAPI Application

Implement `app/main.py` as the application entry point.

Requirements:
1. Initialize a FastAPI instance.
2. Configure the application title and description.
3. Load applicable settings from `app/core/config.py`.
4. Register the routers from `app/routers/`.
5. Avoid circular imports.
6. Keep the implementation simple and readable.
7. Make the application importable as `app.main:app`.

Implement a health endpoint:

`GET /health`

Expected response:

```json
{
  "status": "ok",
  "service": "dermascan-backend"
}
```

The health endpoint must not depend on database availability, Cloudflare R2, authentication, or machine-learning inference.

The API must not use `/v1` or `/v2` prefixes. All routes should follow the requested non-versioned architecture.

Ensure the development API documentation is available through FastAPI's default documentation interface.

## 9. Router Initialization

Implement minimal routers in:
- `app/routers/users.py`
- `app/routers/items.py`

Requirements:
- Define an `APIRouter` in each module.
- Register the routers in `app/main.py`.
- Ensure the application imports and starts successfully.
- Do not implement registration, login, item creation, database operations, or CRUD functionality.

If useful for verifying router registration, add a minimal informational endpoint to each router. Clearly document that these endpoints only verify the initial application structure and are not production business features.

Avoid returning fabricated user records, stored items, or successful database operations.

## 10. Requirements for `run.sh`

Create a runnable `run.sh` script for local development.

Requirements:
- Use a valid Bash shebang.
- Enable strict shell behavior where appropriate.
- Start Uvicorn using `app.main:app`.
- Use a configurable development port, defaulting to `8000`.
- Enable reload for local development.
- Execute from the repository root or reliably resolve the project root.
- Ensure the script is executable where the operating system supports executable permissions.

Example command:

```bash
./run.sh
```

Also document the cross-platform alternative:

```bash
python -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

On Windows, explain how to use the Python command if Bash is unavailable.

Do not configure this development script as a production deployment solution.

## 11. Git Configuration

Create `.gitignore` with appropriate exclusions for:
- `.env`.
- Python virtual environments.
- `__pycache__/`.
- Python bytecode.
- `.pytest_cache/`.
- Coverage artifacts.
- IDE-specific files.
- Local logs and temporary files.
- Generated model artifacts and private datasets where applicable.

Keep source code, tests, `requirements.txt`, and documentation tracked.

Do not initialize Git again if the repository is already under version control.

## 12. Automated Testing

Use pytest and FastAPI's `TestClient` or HTTPX.

Create:
- `tests/test_main.py`
- `tests/test_users.py`
- `tests/test_items.py`

Test requirements:
1. The application can be imported.
2. `GET /health` returns HTTP 200.
3. The health response contains the expected status and service name.
4. The registered user router behaves as expected for the implemented scope.
5. The registered item router behaves as expected for the implemented scope.
6. Unknown routes return HTTP 404.
7. Tests do not require external services, production credentials, a database, or an ML model.

If a router has no endpoints yet, test its registration or explicitly document that no business endpoint has been implemented. Do not add fake business functionality just to make a test pass.

Run the test suite and report the actual result.

## 13. README Documentation

Create a practical `README.md` containing:

- Project overview.
- Technology stack.
- Prerequisites.
- Folder structure and directory responsibilities.
- Python virtual environment setup.
- Dependency installation.
- `.env` configuration.
- How to run the application using `run.sh`.
- The equivalent Uvicorn command.
- Health-check endpoint.
- FastAPI documentation URLs.
- Automated testing instructions.
- Current implementation scope.
- Features deferred to subsequent development tasks.

Make the instructions suitable for team members using Windows, macOS, or Linux where practical.

Clearly distinguish implemented functionality from planned functionality.

## 14. Scope Restrictions

Do not implement the following features in PBL-04:
- User registration and login.
- JWT generation or validation.
- Password hashing.
- Database connectivity or ORM models.
- Database migrations.
- Cloudflare R2 integration.
- Image uploads.
- Machine-learning inference.
- Skin-condition classification.
- GEA scoring.
- Analysis history.
- Educational content APIs.
- Production deployment infrastructure.

The folder structure prepares for these features but does not imply that they already exist.

Do not install dependencies merely because a future directory has been created.

## 15. Execution Workflow

Follow this workflow:

### Phase 1: Inspect
Inspect the repository, existing files, Git state, and Python environment.

### Phase 2: Plan
Confirm the target structure and dependency choices. Identify conflicts with existing files before modifying them.

### Phase 3: Implement
Create the required directory structure and files. Configure dependencies, environment settings, the FastAPI entry point, router registration, the health endpoint, tests, `.gitignore`, and documentation.

### Phase 4: Verify
Install dependencies in a virtual environment. Run pytest. Start the application or perform a valid startup check. Fix implementation errors where possible.

### Phase 5: Report
Provide:
1. A summary of completed changes.
2. The final folder tree.
3. The purpose of each important file.
4. Exact setup and execution commands.
5. Actual test results.
6. Any unresolved issues.
7. A suggested next task for the DermaScan backend.

If direct repository access is available, make the changes directly. Otherwise, provide complete, copy-ready files and commands.

## 16. Definition of Done

PBL-04 is complete when:
- The specified folder structure exists.
- `requirements.txt` contains the required compatible dependencies.
- Configuration is centralized in `app/core/config.py`.
- Local environment settings are excluded from Git.
- The FastAPI application starts successfully.
- `GET /health` returns the expected response.
- User and item routers are registered without implementing future business features.
- The test suite passes, or any execution limitations are explicitly reported.
- `run.sh` works in a compatible shell.
- `README.md` enables another developer to set up and run the project.

**Final instruction:** Follow the specified folder structure exactly, do not introduce API versioning, use `requirements.txt` for dependency management, and prioritize simplicity, maintainability, and reproducibility. Implement only the repository foundation required for PBL-04.