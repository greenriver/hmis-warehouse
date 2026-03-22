# 8 Cross-cutting Concepts

[← Previous: 7 Deployment View](../07-deployment.md) | [Table of Contents](../README.md) | [Next: 9 Architecture Decisions →](../09-decisions.md)

This section describes cross-cutting concepts — practices, patterns, and solution strategies that apply across multiple [building blocks](../05-building-blocks/05-0-building-blocks.md). Where Section 5 shows *what* the system is made of and Section 6 shows *how* it behaves, this section explains the recurring *rules and patterns* that keep those parts consistent.

### What belongs here

A concept belongs in this section when it:

- Applies to **more than one** building block or module (e.g., authorization rules that span Warehouse, HMIS, and CAS).
- Describes a **pattern or convention** rather than a specific component (e.g., the driver module pattern, not a single driver).
- Would be **confusing to repeat** in every building block that uses it.

Each concept should explain *how* it works with enough detail for a new developer to understand the approach, including links back to the building blocks and runtime scenarios where it appears.

### Concepts

- **[8.1 HMIS Data Model](08-1-hmis-data-model.md)** — Entity relationships and data structures based on HUD specifications.
- **[8.2 Security & Access Control](08-2-security.md)** — Authorization model, permission system, role hierarchy, and data visibility rules.
- **[8.3 Driver Module Pattern](08-3-driver-module-pattern.md)** — The internal modularity convention used to organize features within the Rails monolith.
- **[8.4 Background Processing & Monitoring](08-4-background-processing.md)** — Delayed Job patterns, job lifecycle, and observability across the platform.
- **[8.5 Report Framework](08-5-report-framework.md)** — Common infrastructure for HUD compliance reports and operational dashboards.
