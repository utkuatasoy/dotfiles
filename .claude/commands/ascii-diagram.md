# ASCII Architecture Diagram Generator

Create ASCII art diagrams for architecture descriptions.

---

## Instructions

When the user describes an architecture, system, or flow:

1. **Understand the structure** - components, connections, data flow
2. **Choose the best layout** - horizontal, vertical, or hierarchical
3. **Draw the ASCII diagram** using proper box-drawing characters
4. **Add labels and annotations** where needed

---

## ASCII Toolkit

### Boxes
```
┌─────────┐   ╔═════════╗   ┏━━━━━━━━━┓
│  Normal │   ║  Double ║   ┃  Bold   ┃
└─────────┘   ╚═════════╝   ┗━━━━━━━━━┛
```

### Arrows
```
───▶  ◀───  ───▷  ◁───
  │     ▲     │     △
  ▼     │     ▽     │
════▶  ◀════  ─ ─▶  ◀─ ─
```

### Connectors
```
┬  ┴  ├  ┤  ┼  ┌  ┐  └  ┘
```

---

## Layout Patterns

### Horizontal Flow
```
┌───────┐      ┌───────┐      ┌───────┐
│   A   │ ───▶ │   B   │ ───▶ │   C   │
└───────┘      └───────┘      └───────┘
```

### Vertical Flow
```
┌───────┐
│   A   │
└───┬───┘
    │
    ▼
┌───────┐
│   B   │
└───────┘
```

### Branching
```
                    ┌───────┐
              ┌────▶│   B   │
              │     └───────┘
┌───────┐     │
│   A   │─────┤
└───────┘     │     ┌───────┐
              └────▶│   C   │
                    └───────┘
```

### Bidirectional
```
┌───────┐ ◀────▶ ┌───────┐
│   A   │        │   B   │
└───────┘        └───────┘
```

### Grouped/Layered
```
╔═══════════════════════════════╗
║          Frontend             ║
║  ┌─────────┐    ┌─────────┐   ║
║  │ React   │    │  Vue    │   ║
║  └─────────┘    └─────────┘   ║
╚═══════════════════════════════╝
            │
            ▼
╔═══════════════════════════════╗
║          Backend              ║
╚═══════════════════════════════╝
```

---

## Style Guidelines

- Use **single-line boxes** (`┌─┐`) for components
- Use **double-line boxes** (`╔═╗`) for groups/layers
- Keep consistent spacing between elements
- Align boxes properly
- Use clear, readable labels inside boxes
- Add flow direction indicators

---

## Arguments

`$ARGUMENTS` - Description of the architecture to draw

---

## Examples

**User:** "3-tier web architecture"

**Output:**
```
┌─────────────────────────────────────────────────────┐
│                     CLIENT                          │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐              │
│  │ Browser │  │ Mobile  │  │   CLI   │              │
│  └────┬────┘  └────┬────┘  └────┬────┘              │
└───────┼────────────┼────────────┼───────────────────┘
        │            │            │
        └────────────┼────────────┘
                     ▼
┌─────────────────────────────────────────────────────┐
│                   API LAYER                         │
│  ┌──────────────────────────────────────────────┐   │
│  │              Load Balancer                   │   │
│  └─────────────────────┬────────────────────────┘   │
│            ┌───────────┼───────────┐                │
│            ▼           ▼           ▼                │
│       ┌────────┐  ┌────────┐  ┌────────┐            │
│       │ API 1  │  │ API 2  │  │ API 3  │            │
│       └────────┘  └────────┘  └────────┘            │
└─────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────┐
│                   DATA LAYER                        │
│       ┌──────────┐          ┌──────────┐            │
│       │ Postgres │ ◀──────▶ │  Redis   │            │
│       └──────────┘          └──────────┘            │
└─────────────────────────────────────────────────────┘
```

**User:** "microservices with message queue"

**Output:**
```
┌──────────┐     ┌──────────┐     ┌──────────┐
│ Service  │     │ Service  │     │ Service  │
│    A     │     │    B     │     │    C     │
└────┬─────┘     └────┬─────┘     └────┬─────┘
     │                │                │
     └────────────────┼────────────────┘
                      ▼
            ┌──────────────────┐
            │   Message Queue  │
            │     (Kafka)      │
            └────────┬─────────┘
                     │
     ┌───────────────┼───────────────┐
     ▼               ▼               ▼
┌─────────┐    ┌─────────┐    ┌─────────┐
│ Worker  │    │ Worker  │    │ Worker  │
│    1    │    │    2    │    │    3    │
└─────────┘    └─────────┘    └─────────┘
```
