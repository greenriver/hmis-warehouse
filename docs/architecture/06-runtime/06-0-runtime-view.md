# 6 Runtime View

[← Previous: 5 Building Block View](../05-building-blocks/05-0-building-blocks.md) | [Table of Contents](../README.md) | [Next: 7 Deployment View →](../07-deployment.md)

This section describes the behavior and interactions of the system's [building blocks](../05-building-blocks/05-0-building-blocks.md) at runtime through key scenarios. Where Section 5 shows the static structure, this view shows how those blocks collaborate to accomplish real work.

Scenarios are selected for **architectural relevance** — they illustrate important integration points, concurrency boundaries, or error-handling strategies. The goal is a representative selection, not exhaustive coverage.

### What belongs here

Arc42 recommends documenting scenarios from four categories:

- **Use cases and features** — how building blocks execute important workflows (e.g., data entry, report generation).
- **External interface interactions** — how the system cooperates with users, upstream data partners, and external services.
- **Operations** — launch, start-up, shutdown, and scheduled maintenance behavior.
- **Error and exception handling** — how the system responds to failures at architectural boundaries.

### Scenario format

Each scenario should include:

1. **Scenario Description** — what happens and why it matters architecturally.
2. **Involved Building Blocks** — links back to the relevant [Section 5](../05-building-blocks/05-0-building-blocks.md) components.
3. **Runtime Diagram** — sequence diagram, activity diagram, or numbered steps.
4. **Notable Aspects** — architectural decisions, trade-offs, or constraints visible in this scenario.

See [6.1 Login Flow](06-1-login-flow.md) for the established format.

## Scenarios

- **[6.1 Login Flow](06-1-login-flow.md)** — Authentication from browser through OAuth2-Proxy, Dex, and Keycloak back to the Warehouse Application.
- **[6.2 HUD CSV Import](06-2-data-sync.md)** — Ingestion of HUD CSV data from S3 into the Warehouse, including file validation and record normalization.
