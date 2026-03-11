# Per-CSV Import Monitoring

## Overview

Detect significant changes at the individual CSV level during HUD CSV imports. Configure per-CSV alerts to identify issues such as projects added/removed, missing Services.csv, or large "long pull" data updates.

## Features

- **Per-data-source, per-CSV configuration**: Monitor specific CSV files (e.g., Client.csv, Services.csv) for each data source
- **Delta (net change) thresholds**: Alert when row count increase or decrease exceeds a raw count (`count_increase_threshold`, `count_decrease_threshold`)
- **Minimum additions**: Alert when `added` is below a threshold (`min_additions_threshold`), e.g. expect at least 500 new service records/day
- **Maximum removals**: Alert when `removed` exceeds a threshold (`max_removals_threshold`), e.g. alert if more than 100 enrollments deleted in a day
- **Multiple monitors per data source**: Configure separate monitors for different CSV files
- **Post-import triggering**: Runs after each completed import (not on a schedule)
- **Configurable notification recipients**: Via NotificationConfiguration per monitor (Add Notification on each monitor's Edit page)

## Data Flow

1. Import completes; `importer_log.summary` contains per-file counts (pre_processed, added, removed)
2. `CsvImportMonitorCollector` runs for the data source
3. `MetricDefinition.maintain_csv_metrics!` ensures MetricDefinitions exist with `subtype` set per CSV file
4. For each active monitor: compare current counts to previous (from MetricSnapshot or prior ImporterLog)
5. Create/update MetricSnapshot with current value for next comparison
6. If threshold exceeded (per direction and count/percent rules): send email to configured users

## Configuration

- **CSV file**: Select from standard HUD CSV set (Client.csv, Services.csv, Project.csv, etc.)
- **Count increase/decrease**: Optional raw count threshold for net change (delta)
- **Min additions**: Optional threshold; alert when `added` is below this (e.g. 500 for 50% of 1,000 beds)
- **Max removals**: Optional threshold; alert when `removed` exceeds this (e.g. 100 for enrollment deletions)
- **Numeric thresholds only**: Count-based thresholds (no percent)
- **Notifications**: Add recipients via "Add Notification" on each monitor's Edit page (per monitor)

## Location

- **Import Thresholds** page (`/data_sources/:id/import_threshold`): Embedded "Per-CSV Import Monitors" section with list of monitors; Add Monitor, Edit, Remove

## Architecture

- **ImportCsvMonitor**: Model storing per-(data_source, csv_file) config (thresholds)
- **ImportFileDeltaCalculator**: Encapsulates delta (net change) logic; compares pre_processed diff to count thresholds
- **ImportFileAdditionRemovalDetectionCalculator**: Min additions (`added < X`) and max removals (`removed > X`)
- **MetricDefinition** (csv_import): One per CSV file; `subtype` identifies the file (e.g., Client.csv); created/updated by `maintain_csv_metrics!` (called at start of each collection)
- **MetricSnapshot**: Stores current row count per data source per CSV for comparison
- **CsvRowCountCalculator**: Extracts current/previous values from import summaries
- **CsvImportMonitorCollector**: Runs post-import; updates snapshots, delegates to calculators; uses NotificationConfiguration for recipients
- **NotificationConfiguration** (source: ImportCsvMonitor, slug: csv_import_threshold_exceeded): Recipients configured per monitor on each monitor's Edit page
- **NotifyUser.csv_change_threshold_exceeded**: Email template for alerts (supports delta, min_additions, max_removals)

## Related

- [Metric Tracking](metric-tracking.md) — Shared MetricDefinition/MetricSnapshot framework; CSV monitoring uses import logs and post-import trigger
