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
5. If threshold exceeded: create new MetricSnapshot; otherwise update existing snapshot
6. Notifications: sent by the daily MetricSnapshotCollector / CollectClientMetricsJob (same as other metric alerts)

## Configuration

- **CSV file**: Select from standard HUD CSV set (Client.csv, Services.csv, Project.csv, etc.)
- **Count increase/decrease**: Optional raw count threshold for net change (delta)
- **Min additions**: Optional threshold; alert when `added` is below this (e.g. 500 for 50% of 1,000 beds)
- **Max removals**: Optional threshold; alert when `removed` exceeds this (e.g. 100 for enrollment deletions)
- **Numeric thresholds only**: Count-based thresholds (no percent)
- **Notifications**: Add recipients via "Add Notification" on each monitor's Edit page (per monitor)

## Location

- **Import Thresholds** page (`/data_sources/:id/import_threshold`): Embedded "Per-CSV Import Monitors" section with list of monitors; Add Monitor, Edit, View chart (for users with warehouse alerts permission), Remove
- **Admin Metric Definitions** (`/admin/metric_definitions`): CSV import metrics are excluded from the main list; a "CSV Import Thresholds (by Data Source)" section links to each data source's Import Thresholds page

## Architecture

- **ImportCsvMonitor**: Model storing per-(data_source, csv_file) config (thresholds)
- **ImportFileDeltaCalculator**: Encapsulates delta (net change) logic; compares pre_processed diff to count thresholds
- **ImportFileAdditionRemovalDetectionCalculator**: Min additions (`added < X`) and max removals (`removed > X`)
- **MetricDefinition** (csv_import): One per CSV file; `subtype` identifies the file (e.g., Client.csv); created/updated by `maintain_csv_metrics!` (called at start of each collection)
- **MetricSnapshot**: Stores current row count per data source per CSV for comparison
- **CsvRowCountCalculator**: Extracts current/previous values from import summaries
- **CsvImportMonitorCollector**: Runs post-import; creates/updates MetricSnapshots; delegates to calculators for threshold checks
- **NotificationConfiguration** (source: ImportCsvMonitor, slug: csv_import_threshold_exceeded): Recipients configured per monitor on each monitor's Edit page; used by NotifyMetricThresholdCrossingsJob when it runs
- **NotifyMetricThresholdCrossingsJob**: Invoked by the daily MetricSnapshotCollector / CollectClientMetricsJob; sends emails via NotifyUser.metric_threshold_crossed (supports delta, min_additions, max_removals)

## Related

- [Metric Tracking](metric-tracking.md) — Shared MetricDefinition/MetricSnapshot framework; CSV monitoring uses import logs and post-import trigger
