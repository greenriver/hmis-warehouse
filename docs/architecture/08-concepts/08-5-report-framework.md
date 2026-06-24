# 8.5 Report Framework

[← 8.4 Background Processing](08-4-background-processing.md) | [Table of Contents](../README.md) | [Next: 9 Architecture Decisions →](../09-decisions.md)

*TBD. This concept should document the common infrastructure shared by HUD compliance reports and operational dashboards.*

### Planned Scope

- **Report base classes** — The shared superclass and lifecycle (setup, compute, persist, render) that all report drivers follow.
- **Generator pattern** — How individual report sections are computed and assembled.
- **Question/answer framework** — The cell-based structure used by HUD APR, SPM, and similar tabular reports (see `docs/features/hud-report-framework.md`).
- **Filtering and scoping** — How reports are parameterized by date range, project, CoC, and sub-population.
- **Sub-population filters** — The cross-cutting filter modules (`veterans_sub_pop`, `adults_with_children_sub_pop`, etc.) used across multiple reports.
- **Export and rendering** — How report results are rendered to HTML, Excel, and HUD CSV upload formats.

### Related Building Blocks

- [5.2.1 Warehouse Application](../05-building-blocks/05-2-1-warehouse.md) — The HUD Reporting and Warehouse Reports driver groups.

### Related Feature Documentation

- [`docs/features/hud-report-framework.md`](../../features/hud-report-framework.md)
- [`docs/features/hud_spm_report.md`](../../features/hud_spm_report.md)
- [`docs/features/hopwa_caper.md`](../../features/hopwa_caper.md)
