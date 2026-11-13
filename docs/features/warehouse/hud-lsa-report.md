---
sources:
  - drivers/hud_lsa/app/models/hud_lsa/generators/fy2027/lsa.rb
  - drivers/hud_lsa/app/models/hud_lsa/generators/fy2027/rds_concern.rb
  - drivers/hud_lsa/app/models/hud_lsa/generators/retired_lsa_stub.rb
  - drivers/hud_lsa/app/jobs/hud_lsa/run_report_job.rb
  - lib/rds_sql_server/sql_server_base.rb
  - .github/workflows/lsa_integration_test.yml
---

# HUD LSA Report

The Longitudinal System Analysis (LSA) is HUD's own T-SQL script, so the warehouse doesn't compute it in Ruby. Each run exports HMIS CSV for the selected projects, loads it into a temporary Microsoft SQL Server database on AWS RDS, runs HUD's SQL there, and downloads the result and intermediate tables as zip files attached to the report. The temporary instance is dropped when the run ends. The same class produces the HIC when the LSA scope option is set to HIC.

Unlike the other HUD reports, the LSA does not use `GeneratorBase` and questions. The generator subclasses `HudReports::ReportInstance` directly and runs in `HudLsa::RunReportJob` on the long-running queue with a single attempt. See [HUD Report Framework](hud-report-framework.md) for the framework it sits beside.

## SQL Server execution

- Setting `LSA_DB_HOST` points the run at a static SQL Server instead of creating an RDS instance. Cleanup only removes the instance when `LSA_DB_HOST` is blank and `destroy_rds?` is true. Setting `destroy_rds = false` (useful when re-running locally) leaves a billed instance running.
- Without `RDS_AWS_ACCESS_KEY_ID`, or with `NO_LSA_RDS` set, the SQL Server code isn't loaded. A stub `Rds` class reports RDS as unavailable so views still render, and nothing LSA-related can run.
- The LSA is not thread safe. The SQL Server connection class keeps the instance, host, and database in class-level accessors, and each run assigns them globally. Run one LSA per process, and don't extend that pattern.

## Fiscal years

FY2027 is the current generator and FY2026 is a near-copy that is still active. FY2022 through FY2024 are retired: they keep only the model, downloads, and archival, and their T-SQL is deleted. A re-run of a retired year means restoring code from history. Copy the newest year, not a retired one, when adding a year.

## Testing

Unit specs never touch SQL Server. The only automated coverage is a GitHub workflow that runs the FY2027 LSA and HIC end to end in test mode against a SQL Server 2022 container and compares the output to fixtures. FY2026 has no automated coverage.
