# 6.2 HUD CSV Import

[← 6.1 Login Flow](06-1-login-flow.md) | [Table of Contents](../README.md) | [Next: 7 Deployment View →](../07-deployment.md)

*TBD: Runtime behavior for importing HUD CSV files from S3 into the Warehouse — file validation, source record creation, and normalization into the unified warehouse schema.*

## Involved Building Blocks

- **[Warehouse Application](../05-building-blocks/05-2-1-warehouse.md)** — Data Ingestion module (`hmis_csv_importer` and related drivers).
- **S3 Storage** — Ingestion boundary where upstream partners deposit CSV exports.
- **Warehouse Database** — Destination for source and normalized records.
