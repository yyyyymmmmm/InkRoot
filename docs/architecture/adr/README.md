# Architecture Decision Records (ADR)

This directory contains Architecture Decision Records (ADRs) for InkRoot.

---

## 📖 What is an ADR?

An Architecture Decision Record (ADR) documents an important architectural decision made along with its context and consequences.

### Why Use ADRs?

- **Historical Context**: Understand why decisions were made
- **Team Alignment**: Keep everyone on the same page
- **Knowledge Sharing**: Help new team members understand the architecture
- **Decision Tracking**: Track the evolution of the architecture

---

## 📋 ADR Index

| ADR | Title | Status | Date |
|-----|-------|--------|------|
| [001](001-use-provider-for-state-management.md) | Use Provider for State Management | Accepted | 2025-01-15 |
| [002](002-sqlite-for-local-storage.md) | Use SQLite for Local Storage | Accepted | 2025-01-15 |
| [003](003-memos-api-integration.md) | Integrate with Memos API v1 | Accepted | 2025-02-01 |
| [004](004-material-design-3.md) | Adopt Material Design 3 | Accepted | 2025-03-10 |
| [005](005-layered-architecture.md) | Implement Layered Architecture | Accepted | 2025-03-15 |
| [006](006-deepseek-ai-integration.md) | Integrate DeepSeek AI for Smart Features | Accepted | 2025-09-20 |
| [007](007-umeng-analytics.md) | Use Umeng for Analytics | Accepted | 2025-10-01 |

---

## 📝 ADR Status

- **Proposed**: Decision under consideration
- **Accepted**: Decision approved and implemented
- **Deprecated**: Decision no longer valid but kept for historical context
- **Superseded**: Replaced by a newer decision

---

## ✍️ Creating a New ADR

### 1. Use the Template

Copy the [template.md](template.md) to create a new ADR.

### 2. Naming Convention

```
NNN-title-with-dashes.md
```

Examples:
- `001-use-provider-for-state-management.md`
- `008-implement-offline-mode.md`

### 3. Fill Out All Sections

- **Title**: Short, descriptive title
- **Status**: Proposed, Accepted, Deprecated, or Superseded
- **Context**: What is the issue we're facing?
- **Decision**: What decision did we make?
- **Consequences**: What are the trade-offs?

### 4. Review and Discuss

- Open a pull request
- Get feedback from the team
- Update based on feedback
- Merge when consensus is reached

---

## 🎯 ADR Template

See [template.md](template.md) for the complete template.

Quick example:

```markdown
# NNN. Title

Date: YYYY-MM-DD

## Status

Proposed / Accepted / Deprecated / Superseded

## Context

What is the issue that we're seeing that is motivating this decision?

## Decision

What is the change that we're proposing?

## Consequences

What becomes easier or more difficult to do because of this change?
```

---

## 📚 ADR Best Practices

### Do's

- ✅ Keep ADRs short and focused
- ✅ Write in simple, clear language
- ✅ Include diagrams when helpful
- ✅ Document alternatives considered
- ✅ Explain trade-offs clearly
- ✅ Update status as needed

### Don'ts

- ❌ Don't delete old ADRs (mark as superseded instead)
- ❌ Don't be too technical or too vague
- ❌ Don't skip the "Consequences" section
- ❌ Don't make decisions without discussion

---

## 🔗 References

- [ADR GitHub Organization](https://adr.github.io/)
- [Documenting Architecture Decisions](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions)
- [Architectural Decision Records](https://www.thoughtworks.com/radar/techniques/lightweight-architecture-decision-records)

---

<div align="center">

[Back to Architecture Documentation](../README.md) | [View Template](template.md)

</div>

