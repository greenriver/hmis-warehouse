# Per-CSV Import Monitoring

## Overview

Detect significant changes at the individual CSV level during HUD CSV imports. Configure per-CSV alerts to identify issues such as projects added/removed, missing Services.csv, or large "long pull" data updates.

## Features

- **Per-data-source, per-CSV configuration**: Monitor specific CSV files (e.g., Client.csv, Services.csv) for each data source
- **Count and/or percent thresholds**: Alert when row counts change by a raw count or percentage
- **Direction derived from thresholds**: Only increase thresholds set → alerts on additions only; only decrease thresholds set → alerts on removals only; both → alerts on either
- **Multiple monitors per data source**: Configure separate monitors for different CSV files
- **Post-import triggering**: Runs after each completed import (not on a schedule)
- **Configurable notification recipients**: Add users to receive email alerts per monitor

## Data Flow

1. Import completes; `importer_log.summary` contains per-file counts (pre_processed, added, removed)
2. `CsvImportMonitorCollector` runs for the data source
3. `MetricDefinition.maintain_csv_metrics!` ensures MetricDefinitions exist with `subtype` set per CSV file
4. For each active monitor: compare current counts to previous (from MetricSnapshot or prior ImporterLog)
5. Create/update MetricSnapshot with current value for next comparison
6. If threshold exceeded (per direction and count/percent rules): send email to configured users

## Configuration

- **CSV file**: Select from standard HUD CSV set (Client.csv, Services.csv, Project.csv, etc.)
- **Count thresholds**: Optional min count for increase or decrease
- **Percent thresholds**: Optional percent for increase or decrease
- **Direction**: Inferred from which thresholds are set (increase only, decrease only, or both)
- **Notifications**: Add users via the monitor edit page

## Location

- **Import Thresholds** page (`/data_sources/:id/import_threshold`): Embedded "Per-CSV Import Monitors" section with list of monitors; Add Monitor, Edit, Remove; add notification recipients via Edit

## Architecture

- **ImportCsvMonitor**: Model storing per-(data_source, csv_file) config (thresholds, recipients; direction inferred from which thresholds are set)
- **MetricDefinition** (csv_import): One per CSV file; `subtype` identifies the file (e.g., Client.csv); created/updated by `maintain_csv_metrics!` (called at start of each collection)
- **MetricSnapshot**: Stores current row count per data source per CSV for comparison
- **CsvRowCountCalculator**: Extracts current/previous values from import summaries
- **CsvImportMonitorCollector**: Runs post-import; updates snapshots, compares thresholds, sends notifications
- **NotifyUser.csv_change_threshold_exceeded**: Email template for alerts

## Related

- [Metric Tracking](metric-tracking.md) — Shared MetricDefinition/MetricSnapshot framework; CSV monitoring uses import logs and post-import trigger
