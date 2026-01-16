# Generate README.md Documentation

You are a technical documentation writer.
Your task is to analyze the repository and generate a clear, concise `README.md` that helps developers quickly understand and use the project.

The output must be written in **professional technical English**, easy to follow, and based on repository evidence.

---

## Required Output: `README.md`

Generate a README with the following sections:

---

## 1. Project Title & Description
- Project name as H1 header
- 2-3 sentence description of what the project does
- Key value proposition

---

## 2. Tech Stack (Brief)
List the main technologies in a simple bullet list:
- Language & version
- Framework
- Database
- Key libraries (LLM, vector search, etc.)
- Package manager

---

## 3. Prerequisites
What developers need before starting:
- Required software versions
- External services/dependencies
- Installation links for tools

---

## 4. Quick Start

### Installation
Step-by-step commands to install dependencies.

### Environment Setup
- Copy `.env.example` to `.env`
- List key environment variables that must be configured

### Run the Application
Commands to start the application locally.

---

## 5. Project Structure
A simplified tree view showing only the main directories:
```
project/
├── app/           # Brief description
├── tests/         # Brief description
├── alembic/       # Brief description (if exists)
└── ...
```

---

## 6. API Endpoints (if applicable)
Table or list of main endpoints:
| Method | Endpoint | Description |
|--------|----------|-------------|

Include link to Swagger docs if available.

---

## 7. Development

### Running Tests
Commands to run unit and integration tests.

### Code Quality
Commands for linting, formatting, type checking.

### Database Migrations
Basic commands for creating and applying migrations.

---

## 8. Deployment
Brief deployment instructions:
- Docker build command
- Environment considerations
- Link to detailed deployment docs if exists

---

## 9. Contributing (Optional)
Brief contribution guidelines if the project accepts contributions.

---

## Formatting Requirements
- Use **Markdown**
- Keep it concise - developers should understand the project in 2-3 minutes
- Use code blocks for all commands
- Include copy-paste ready examples
- Do NOT include sections that don't apply to the project
- Base all information on repository evidence

---

## Arguments
If the user provides arguments, consider them:
- `$ARGUMENTS` - Any specific focus areas or customizations requested

Return **only** the final `README.md` content.
