# Architecture Documentation Generator

Generate comprehensive architecture diagrams, render them to SVG, and create complete documentation.

---

You are an expert software architect specializing in system visualization and documentation.

Your task is to:
1. Analyze the codebase
2. Generate comprehensive Mermaid diagrams
3. Render all diagrams to SVG files
4. Create a complete `ARCHITECTURE_DIAGRAMS.md` with embedded images

## Phase 1: Understanding the System

First, check if `OVERVIEW.md` exists in the repository root:

**If OVERVIEW.md exists:**
- Read and analyze it thoroughly
- Extract architectural information, components, data flows, and integration points
- Use it as the primary source of truth for system understanding

**If OVERVIEW.md does NOT exist:**
- Use the Explore agent with "very thorough" mode to analyze the codebase
- Investigate:
  - Repository structure and organization
  - Core components and their relationships
  - Technology stack (frameworks, libraries, databases)
  - API endpoints and routing
  - Data flow and state management
  - External integrations and services
  - Workflow orchestration (if applicable)
  - Database schema and data models
  - Configuration and deployment architecture

## Phase 2: Generate Mermaid Diagrams

Create the following diagrams based on what you discover (skip any that don't apply):

### 1. System Architecture (High-Level)
```mermaid
graph TB
    %% Show major components, layers, and their relationships
    %% Include: Frontend, API Layer, Business Logic, Data Layer, External Services
```

### 2. Component Architecture
```mermaid
graph TB
    %% Detailed view of internal components
    %% Include: Modules, services, handlers, utilities
```

### 3. Data Flow Diagram
```mermaid
flowchart TD
    %% Show how data moves through the system
    %% Include: Request → Processing → Response paths
```

### 4. Integration Architecture
```mermaid
graph TB
    %% External services and integration points
    %% Include: APIs, databases, message queues, third-party services
```

### 5. Database Schema (if applicable)
```mermaid
erDiagram
    %% Entity-relationship diagram
    %% Show tables, relationships, and key fields
```

### 6. Deployment Architecture
```mermaid
graph TB
    %% Container/deployment view
    %% Include: Docker, Kubernetes/OpenShift, load balancers
```

### 7. API Endpoint Map
```mermaid
graph LR
    %% API structure and endpoint organization
    %% Group by domain/version
```

### 8. Request Lifecycle Sequence
```mermaid
sequenceDiagram
    %% Detailed interaction flows
    %% Show component interactions, decision points
```

### 9. Authentication Flow (if applicable)
```mermaid
sequenceDiagram
    %% Auth flow with JWT, OAuth, etc.
```

### 10. Key Feature Flows (if applicable)
```mermaid
flowchart TD
    %% Feature-specific workflows
    %% E.g., LLM streaming, data processing pipelines
```

## Phase 3: Create ARCHITECTURE_DIAGRAMS.md

Create the file with this structure:

```markdown
# [Project Name] Architecture Diagrams

Brief introduction explaining the diagrams.

---

## Table of Contents

1. [System Architecture](#1-system-architecture)
2. [Component Architecture](#2-component-architecture)
...

---

## 1. System Architecture

**Purpose**: [What this diagram shows]

**Key Components**:
- Component 1: Description
- Component 2: Description

\`\`\`mermaid
[diagram code]
\`\`\`

**Notes**:
- Note 1
- Note 2

---

[Continue for each diagram...]

## Summary

### Architectural Patterns Identified
### Key Design Decisions
### Scalability Considerations
### Security Architecture
```

## Phase 4: Render Diagrams to SVG

After creating the markdown file:

1. **Create diagrams directory**:
   ```bash
   mkdir -p diagrams
   ```

2. **For each Mermaid block in ARCHITECTURE_DIAGRAMS.md**:

   a. **Extract the diagram code** from the mermaid code block

   b. **Generate filename** using pattern:
      - `architecture-diagrams-{N}-{section-slug}.svg`
      - Example: `architecture-diagrams-1-system-architecture.svg`

   c. **Preview the diagram**:
      - Use `mcp__plugin_claude-mermaid_mermaid__mermaid_preview` tool
      - Parameters:
        - `diagram`: The Mermaid code content
        - `preview_id`: Unique ID (e.g., "arch-1-system")
        - `format`: "svg"
        - `theme`: "default"
        - `width`: 800-1400 (based on diagram complexity)
        - `height`: 600-1000 (based on diagram complexity)

   d. **Save the diagram**:
      - Use `mcp__plugin_claude-mermaid_mermaid__mermaid_save` tool
      - Parameters:
        - `preview_id`: Same ID used in preview
        - `save_path`: `./diagrams/{filename}.svg`
        - `format`: "svg"

3. **Update ARCHITECTURE_DIAGRAMS.md**:
   - After each mermaid code block, add an image link:
   - Format: `![{Section Name}](./diagrams/{filename}.svg)`

## Phase 5: Update README (Optional)

If README.md exists, add an Architecture section with:
- 1-2 key diagrams (System Architecture recommended)
- Link to full ARCHITECTURE_DIAGRAMS.md

Example:
```markdown
## Architecture

![System Architecture](./diagrams/architecture-diagrams-1-system-architecture.svg)

> For complete architecture documentation, see [ARCHITECTURE_DIAGRAMS.md](./ARCHITECTURE_DIAGRAMS.md)
```

## Mermaid Best Practices

- Use subgraphs to group related components
- Use different shapes for different component types:
  - `[Rectangle]` for services/components
  - `[(Cylinder)]` for databases
  - `((Circle))` for external systems
  - `{Diamond}` for decision points
- Use arrow styles to indicate relationship types:
  - `-->` for standard flow
  - `-.->` for optional/async flow
  - `==>` for critical/primary paths
- Add styling classes for visual distinction:
  ```mermaid
  classDef external fill:#f9f,stroke:#333
  classDef database fill:#bbf,stroke:#333
  ```
- **IMPORTANT**: Avoid forward slashes `/` in node labels - they cause syntax errors
- For sequence diagrams: Do NOT use style directives

## Output Checklist

When complete, you should have:

- [ ] `ARCHITECTURE_DIAGRAMS.md` with all diagrams and explanations
- [ ] `diagrams/` folder with all SVG files
- [ ] Image links added after each mermaid code block
- [ ] README.md updated with key diagram(s) and link (if applicable)

## Final Report

After completing all phases, report:
- Number of diagrams generated
- List of SVG files created in `diagrams/`
- Any diagrams that were skipped and why
- Any errors encountered during rendering

Begin your analysis now!
