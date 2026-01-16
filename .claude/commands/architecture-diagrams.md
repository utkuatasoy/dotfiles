# Architecture Diagrams Generator

Generate comprehensive Mermaid diagrams for the system architecture.

---

You are an expert software architect specializing in system visualization and documentation.

Your task is to analyze the codebase and generate comprehensive Mermaid diagrams that accurately represent the system architecture.

## Step 1: Understanding the System

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

## Step 2: Generate Mermaid Diagrams

Create the following diagrams based on what you discover:

### 1. System Architecture (High-Level)
```mermaid
graph TB
    %% Show major components, layers, and their relationships
    %% Include: Frontend, API Layer, Business Logic, Data Layer, External Services
```

### 2. Component Architecture
```mermaid
graph LR
    %% Detailed view of internal components
    %% Include: Modules, services, handlers, utilities
```

### 3. Data Flow Diagram
```mermaid
flowchart TD
    %% Show how data moves through the system
    %% Include: Request → Processing → Response paths
```

### 4. Workflow/Pipeline (if applicable)
```mermaid
stateDiagram-v2
    %% For workflow engines like LangGraph
    %% Show nodes, states, transitions, and conditions
```

### 5. Integration Architecture
```mermaid
graph TB
    %% External services and integration points
    %% Include: APIs, databases, message queues, third-party services
```

### 6. Database Schema (if applicable)
```mermaid
erDiagram
    %% Entity-relationship diagram
    %% Show tables, relationships, and key fields
```

### 7. Deployment Architecture
```mermaid
graph TB
    %% Container/deployment view
    %% Include: Docker, Kubernetes/OpenShift, load balancers
```

### 8. API Endpoint Map
```mermaid
graph LR
    %% API structure and endpoint organization
    %% Group by domain/version
```

### 9. Feature-Specific Use Case Flows (if applicable)
```mermaid
flowchart TD
    %% For systems with specific features/use cases
    %% Show how key features work end-to-end
    %% Examples: Real-time processing, dual-mode operations, special workflows
```

### 10. Detailed Sequence Diagrams for Key Use Cases
```mermaid
sequenceDiagram
    %% Detailed interaction flows for important use cases
    %% Show component interactions, decision points, data transformations
```

## Step 3: Output Format

For each diagram:
1. **Provide a clear title and description** explaining what the diagram shows
2. **Use proper Mermaid syntax** with:
   - Clear node labels
   - Descriptive edge labels
   - Logical grouping (subgraphs where appropriate)
   - Consistent styling
3. **Add explanatory notes** below each diagram highlighting:
   - Key architectural decisions
   - Critical paths or flows
   - Important relationships or dependencies
   - Any assumptions made

## Guidelines

- **Accuracy First**: Base all diagrams on evidence from the codebase
- **Clarity**: Use clear, descriptive labels (avoid abbreviations unless well-known)
- **Completeness**: Include all major components, but avoid overwhelming detail
- **Consistency**: Use consistent naming across all diagrams
- **Context**: For complex systems, create multiple levels of detail (overview → detailed views)
- **Technology-Specific**: If the system uses specific frameworks (e.g., LangGraph, FastAPI), use appropriate diagram types:
  - LangGraph → State diagrams or flowcharts showing nodes and edges
  - FastAPI → API routing and middleware layers
  - Microservices → Service mesh and communication patterns
- **Use Case Driven**: Identify and diagram the key use cases and how they flow through the system:
  - Critical user journeys (e.g., user signup, checkout, data processing)
  - Special modes or features (e.g., admin mode, batch processing, real-time streaming)
  - Complex interactions between components
  - Edge cases and error handling flows

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

## Example Output Structure

For each diagram, format as:

```markdown
## [Diagram Number]. [Diagram Title]

**Purpose**: [What this diagram shows]

**Key Components**:
- Component 1: Description
- Component 2: Description

```mermaid
[Your Mermaid diagram here]
```

**Notes**:
- Note 1
- Note 2
```

## Final Deliverable

Create a new file `ARCHITECTURE_DIAGRAMS.md` containing:
1. Brief introduction explaining the diagrams
2. Table of contents linking to each diagram
3. All generated diagrams with explanations
4. A summary section highlighting:
   - Architectural patterns identified
   - Key design decisions
   - Scalability and performance considerations
   - Security architecture

Begin your analysis now and generate comprehensive, accurate Mermaid diagrams based on the codebase!
