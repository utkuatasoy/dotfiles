# Generate Repository Overview Documentation

You are an expert software architect and technical documentation writer.
Your task is to analyze the entire repository and generate a complete, enterprise-grade `OVERVIEW.md` that describes the system accurately and comprehensively.

The output must be written in **professional technical English**, structured cleanly, and based solely on evidence from the repository.

---

## 🔍 Required Output: `OVERVIEW.md`

Your final document must include the following sections:

---

## 1. Project Summary
- High-level explanation of what the repository does
- Core purpose, value, and functional overview
- Any domain-specific responsibilities inferred from the code

---

## 2. Technology Stack
Analyze imports, configs, Dockerfile, dependencies, and CI pipeline to extract:
- Runtime language & versions
- Backend frameworks
- AI/LLM libraries
- Workflow or orchestration tools
- Databases & ORM
- Search/index libraries
- External service integrations
- DevOps, CI/CD, and deployment tools
- Utility libraries
Explain the role of each component in the architecture.

---

## 3. Repository Structure
Produce a tree view and a detailed explanation of:
- Root-level folders
- Module-level responsibilities
- Internal relationships (e.g., API → service → workflow → LLM provider → DB)
- Architectural patterns (layered, modular, node-based, pipeline-based, etc.)

Explain how code units interact across layers.

---

## 4. Core Architecture Components
Describe and analyze the system’s main subsystems:
- API layer
- Workflow or graph engine
- Planning/execution components
- Memory/session management
- LLM abstraction layer
- Vector search or embedding modules
- Database layer
- Background jobs/schedulers
- UI layer (if present)
- Integration protocols (e.g., MCP)

Describe the request lifecycle and data flow where inferable.

---

## 5. Key Features
Infer and describe major system capabilities, such as:
- Intent routing
- Step-based planning & execution
- Real-time streaming
- FAISS or vector search
- Memory/session management
- Function calling
- Multi-agent or multi-node workflows
- Observability (logging, tracing, Langfuse, etc.)

---

## 6. Configuration & Environment Management
Analyze:
- `.env` conventions
- Pydantic/Settings usage
- Dynamic configuration patterns
- Feature flags and environment profiles
- Secrets, API keys, and computed fields

---

## 7. Deployment & Operations
Infer deployment architecture based on:
- Dockerfile
- docker-compose
- OpenShift configs
- Jenkinsfile / CI pipelines

Include details about:
- Build process
- Runtime stack
- Security posture
- Scaling considerations
- Runtime performance strategies

---

## 8. Testing Strategy
Explain:
- Overall test organization
- pytest usage
- async test support
- mocking strategies
- what is being validated

---

## 9. UI Components
If applicable:
- Embedded frontend assets
- Templates
- Web UI layout and interaction points

---

## 10. Performance & Scalability
Analyze architectural choices affecting:
- Async I/O
- Caching layers
- Vector search performance
- Memory/store efficiency
- Session cleanup
- Load distribution
- Multi-tenant considerations (if visible)

---

## 11. Security Considerations
Discuss:
- Authentication/authorization
- Secrets management
- Safe input handling
- SQL injection protections
- Container security
- Dependency update posture

Focus strictly on evidence from the codebase.

---

## 12. Integration Points
Document:
- External APIs
- LLM providers
- MCP functions/protocols
- Databases
- Internal services and adapters

Describe how these components are wired together.

---

## Formatting Requirements
- Use **Markdown**
- Use clear section headers
- Explain reasoning and inferred architecture with precision
- Do **not** hallucinate absent components
- Base all statements on repository evidence

Return **only** the final `OVERVIEW.md` content.
