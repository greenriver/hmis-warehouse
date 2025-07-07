# FY2026 Custom Files Integration Summary

This document explains how the FY2026 custom files system integrates with the existing HMIS import pipeline.

## Overview

The FY2026 custom files system has been integrated into the version-aware HMIS import pipeline, allowing it to automatically process custom CSV files (like CustomGender.csv, CustomDataElement.csv) when FY2026 HMIS exports are uploaded.

## Integration Architecture

### 1. Version Detection Flow

```
1. File Upload → HmisAutoMigrate → Version Detection
2. Version Detection → Importer Selection → FY2026 Importer
3. FY2026 Importer → Custom File Processing → Warehouse Storage
```

### 2. Key Components

#### Version Detection (`app/models/importers/hmis_auto_migrate.rb`)
- Reads `Export.csv` file to determine HMIS version
- Extracts `CSVVersion` field (e.g., "2026")
- Normalizes version strings for consistent routing

#### Importer Selection (`drivers/hmis_csv_importer/app/models/hmis_csv_importer/hmis_csv.rb`)
- Maps versions to importer classes via `Rails.application.config.hmis_importers`
- Provides `importer_class_for_version(version)` method
- Falls back to base importer for unknown versions

#### FY2026 Importer (`drivers/hmis_csv_twenty_twenty_six/app/models/hmis_csv_twenty_twenty_six/importer/importer.rb`)
- Extends base `HmisCsvImporter::Importer::Importer`
- Automatically generates custom models from YAML configuration (NOTE: once generated, updates will probably need different names)
- Processes custom files after standard HMIS overlay

#### Custom File Manager (`drivers/hmis_csv_twenty_twenty_six/app/models/hmis_csv_twenty_twenty_six/custom_file_manager.rb`)
- Dynamically generates Loader, Importer, and Warehouse classes
- Handles column mapping and type conversion
- Supports augmentation, new tables, and key-value stores (TODO: not sure we need all three of these, augmentation and new tables are probably sufficient)

## Configuration Files

### Importer Registration (`config/initializers/hmis_importers.rb`)
```ruby
Rails.application.config.hmis_importers = {
  '2020' => 'HmisCsvImporter::Importer::Importer',
  '2022' => 'HmisCsvImporter::Importer::Importer',
  '2024' => 'HmisCsvImporter::Importer::Importer',
  '2026' => 'HmisCsvTwentyTwentySix::Importer::Importer'  # Contains custom importer, future iterations will want their own importers
}
```

### Data Lake Registration (`drivers/hmis_csv_twenty_twenty_six/config/initializers/hmis_csv_twenty_twenty_six_feature.rb`)
```ruby
Rails.application.config.hmis_data_lakes['2026'] = 'HmisCsvTwentyTwentySix'
```

### Custom File Configuration (`drivers/hmis_csv_twenty_twenty_six/config/custom/*.yaml`)
```yaml
# custom_gender.yaml
custom_files:
  - filename: "CustomGender.csv"
    class_name: "CustomGender"
    augments_warehouse_table: "GrdaWarehouse::Hud::Client"
    columns:
      - name: "PersonalID"
        type: "string"
        required: true
      - name: "Woman"
        type: "integer"
        warehouse_column_mapping:
          type: "direct"
          target_column: "Woman"
```

## Import Process Flow

### 1. File Upload
- User uploads zip file containing HMIS CSV files
- Files may include standard HMIS files and custom files

### 2. File Processing and Extraction
- `HmisAutoMigrate::Base.pre_process()` downloads and normalizes the zip file from S3/local/upload
- `HmisAutoMigrate::Base.expand_upload()` extracts zip file to local directory

### 3. Version Detection and Loader Selection
- `HmisAutoMigrate.calculate_current_version()` reads `Export.csv` to detect version ('2026')
- Applies any necessary migrations to upgrade older formats
- `loader_class_for_version('2026')` → returns `HmisCsvTwentyTwentySix::Loader::Loader`

### 4. Loader Phase
- `HmisCsvTwentyTwentySix::Loader::Loader.new()` automatically generates custom models during initialization
- Migrates CSV files to the appropriate current version
- Loads all CSV files (standard + custom) into data lake tables

### 5. Importer Phase
- `HmisCsvTwentyTwentySix::Importer::Importer.new()` called
- Custom models already generated during loading phase
- Processes standard HMIS files first (via `super`)
- Processes custom files after standard overlay

### 6. Custom File Processing
- Augmentation files: Add/update columns in existing warehouse tables
- New table files: Create records in new warehouse tables
- Key-value stores: Special processing for definition-based data (TODO: do we need this?)

## Example Usage

### Upload Process
1. User uploads `hmis_export_2026.zip` containing:
   - Standard files: `Export.csv`, `Client.csv`, `Project.csv`, etc.
   - Custom files: `CustomGender.csv`, `CustomDataElement.csv`

2. System automatically:
   - Detects FY2026 version from `Export.csv`
   - Routes to `HmisCsvTwentyTwentySix::Importer::Importer`
   - Generates custom models from YAML configuration
   - Processes all files (standard + custom)
