# 8.3 Driver Module Pattern

[← 8.2 Security & Access Control](08-2-security.md) | [Table of Contents](../README.md) | [Next: 8.4 Background Processing →](08-4-background-processing.md)

*TBD. This concept should document the driver module convention — the primary mechanism for organizing features within the Rails monolith.*

### Planned Scope

- **Convention** — Each driver lives in `/drivers/[module]` and mirrors the standard Rails directory structure (`app/models/`, `app/controllers/`, `app/views/`, etc.).
- **Isolation model** — How drivers keep feature-specific logic out of the core `app/` namespace, and what belongs in a driver vs. the shared core.
- **Registration and loading** — How the Rails engine discovers and mounts driver modules at boot time.
- **Inter-driver dependencies** — Rules and patterns for when one driver depends on another (e.g., report drivers depending on shared sub-population filters).
- **Creating a new driver** — Step-by-step guide for adding a new driver module.

### Related Building Blocks

- [5.2.1 Warehouse Application](../05-building-blocks/05-2-1-warehouse.md) — The driver catalog table groups the 88 existing drivers by functional area.
