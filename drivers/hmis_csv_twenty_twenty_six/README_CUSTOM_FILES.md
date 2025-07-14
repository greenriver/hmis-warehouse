# Custom Files System for HMIS CSV Twenty Twenty Six

This document explains how to use the extensible custom files system for importing additional CSV files beyond the standard HUD HMIS specification.

## Overview

The custom files system allows you to import additional CSV files that aren't part of the standard HMIS specification. These files are configured through individual YAML files that define:

- File structure and validation rules
- How data should be processed and stored
- Whether data augments existing tables or creates new ones
- Special processing rules for complex data types

## Quick Start

1. **Create a YAML configuration file** in `drivers/hmis_csv_twenty_twenty_six/config/custom/`
2. **Define your file structure** with columns, validations, and processing rules
3. **Run the bootstrap task** to generate model and migration files
4. **Run the generated migrations**
5. **Upload FY2026 HMIS CSV files** - the system will automatically detect the version and use the FY2026 importer
6. **Custom files are processed automatically** during the import process using the generated models

## Version Detection and Dispatch

The import system automatically detects the HMIS CSV version from the `Export.csv` file and routes to the appropriate loader and importer:

- **Version Detection**: `Importers::HmisAutoMigrate.calculate_current_version()` reads the `CSVVersion` field
- **Loader Selection**: `HmisCsvImporter::HmisCsv.loader_class_for_version()` maps versions to loader classes
- **Importer Selection**: `HmisCsvImporter::HmisCsv.importer_class_for_version()` maps versions to importer classes

**FY2020-2024**: Uses base `HmisCsvImporter::Loader::Loader` and `HmisCsvImporter::Importer::Importer`
**FY2026**: Uses `HmisCsvTwentyTwentySix::Loader::Loader` and `HmisCsvTwentyTwentySix::Importer::Importer` with custom file support

Version mappings are configured in each driver's feature file (e.g., `drivers/hmis_csv_twenty_twenty_six/config/initializers/hmis_csv_twenty_twenty_six_feature.rb`).

## Configuration Structure

### Basic File Configuration

```yaml
# custom_example.yaml
custom_files:
  - filename: "CustomExample.csv"
    class_name: "CustomExample"
    required: false
    description: "Example custom file for demonstration"

    # Choose ONE of these processing types:
    augments_warehouse_table: "GrdaWarehouse::Hud::Client"  # Adds data to existing table
    creates_warehouse_table: true                           # Creates new warehouse table
    key_value_store: true                                   # Special key-value processing

    columns:
      - name: "PersonalID"
        type: "string"
        required: true
        validations: ["NonBlank"]
      - name: "CustomField"
        type: "integer"
        required: false
```

### Column Configuration

Each column can have:

```yaml
columns:
  - name: "ColumnName"           # Required: CSV column name
    type: "string"               # Required: data type (string, integer, date, datetime, boolean)
    required: true               # Optional: whether field is required
    max_length: 255              # Optional: maximum length for strings
    validations:                 # Optional: additional validations
      - "NonBlank"               # Simple validation
      - class: "InclusionInSet"  # Complex validation
        arguments:
          valid_options: ["A", "B", "C"]
    warehouse_column_mapping:    # Optional: how to map to warehouse table
      type: "direct"
      target_column: "WarehouseColumn"
```

## Processing Types

### 1. Augmentation Files

These files add data to existing warehouse tables:

```yaml
# custom_gender.yaml
custom_files:
  - filename: "CustomGender.csv"
    class_name: "CustomGender"
    augments_warehouse_table: "GrdaWarehouse::Hud::Client"
    augment_key: "PersonalID"
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

**Usage**: for restoring fields that were removed from newer HMIS versions but still exist in the warehouse schema.

### 2. New Warehouse Tables

These files create entirely new warehouse tables:

```yaml
# custom_data_element.yaml
custom_files:
  - filename: "CustomDataElement.csv"
    class_name: "CustomDataElement"
    creates_warehouse_table: true
    warehouse_class_name: "GrdaWarehouse::Hud::CustomDataElement"
    columns:
      - name: "CustomDataElementID"
        type: "string"
        required: true
      - name: "Value"
        type: "string"
```

**Usage**: for completely new data types that don't fit into existing warehouse tables.

### 3. Key-Value Stores

These files have special processing for definition-based data:

```yaml
# custom_data_element.yaml
custom_files:
  - filename: "CustomDataElement.csv"
    class_name: "CustomDataElement"
    key_value_store: true
    definition_class: "CustomDataElementDefinition"
    definition_key: "CustomDataElementDefinitionID"
    creates_warehouse_table: true
    warehouse_class_name: "GrdaWarehouse::Hud::CustomDataElement"
```

**Usage**: For files where values are defined by separate definition files (like CustomDataElement + CustomDataElementDefinition).

## Column Mapping Types

### Direct Mapping

```yaml
warehouse_column_mapping:
  type: "direct"
  target_column: "Woman"
```

Maps the source value directly to the target column.

### Value-Based Multi-Column Mapping

```yaml
warehouse_column_mapping:
  type: "value_based_multi_column"
  value_mappings:
    - condition: { value: "1" }
      target_column: "Woman"
      target_value: 1
    - condition: { value: "2" }
      target_column: "Man"
      target_value: 1
```

Maps different source values to different target columns.

### Concatenation Mapping

```yaml
warehouse_column_mapping:
  type: "concatenation"
  target_column: "CombinedField"
  separator: " | "
```

Combines multiple source values into a single target field.

## Model and Migration Generation

The system provides a bootstrapping task to generate the necessary model and migration files for your custom files.

### Automatic Generation

After creating or modifying your YAML configuration files, run the bootstrap task from the project root:

```bash
dcr shell bundle exec rails r "HmisCsvTwentyTwentySix::CustomFileManager.bootstrap_custom_models!"
```

This will:
- Read all YAML files in the `config/custom/` directory
- Generate migration files for any missing tables in `db/warehouse/migrate/`
- Generate loader model files in `drivers/hmis_csv_twenty_twenty_six/app/models/hmis_csv_twenty_twenty_six/loader/custom/`
- Generate importer model files in `drivers/hmis_csv_twenty_twenty_six/app/models/hmis_csv_twenty_twenty_six/importer/custom/`

The generated model and migration files should be committed to your repository.

### Table Naming Conventions

The system follows consistent naming patterns:

- **Loader tables**: `hmis_csv_2026_[plural_class_name]` (e.g., `hmis_csv_2026_custom_genders`)
- **Importer tables**: `hmis_2026_[plural_class_name]` (e.g., `hmis_2026_custom_genders`)
- **Warehouse tables**: `[plural_class_name]` (e.g., `custom_data_elements`)

### Generated Migration Example

For a `CustomGender` configuration, the system generates:

```ruby
# db/warehouse/migrate/20250115120000_create_custom_gender_custom_tables.rb
class CreateCustomGenderCustomTables < ActiveRecord::Migration[7.1]
  def change
    # CustomGender loader table
    create_table :hmis_csv_2026_custom_genders do |t|
      t.string "PersonalID"
      t.string "Woman"
      t.string "Man"
      t.string "NonBinary"
      t.string "CulturallySpecific"
      t.string "Transgender"
      t.string "Questioning"
      t.string "DifferentIdentity"
      t.string "GenderNone"
      t.string "DifferentIdentityText"
      t.string "DateCreated"
      t.string "DateUpdated"
      t.string "UserID"
      t.string "DateDeleted"
      t.string "ExportID"

      # Standard loader columns
      t.references :data_source, null: false, index: true
      t.datetime :loaded_at, null: false
      t.references :loader, null: false, index: true
    end

    # Add indexes for loader table
    add_index :hmis_csv_2026_custom_genders, [:PersonalID, :data_source_id], name: "idx_custom_genders_id_ds"

    # CustomGender importer table
    create_table :hmis_2026_custom_genders do |t|
      t.string "PersonalID"
      t.integer "Woman"
      t.integer "Man"
      t.integer "NonBinary"
      t.integer "CulturallySpecific"
      t.integer "Transgender"
      t.integer "Questioning"
      t.integer "DifferentIdentity"
      t.integer "GenderNone"
      t.string "DifferentIdentityText"
      t.datetime "DateCreated"
      t.datetime "DateUpdated"
      t.string "UserID"
      t.datetime "DateDeleted"
      t.string "ExportID"

      # Standard importer columns
      t.references :data_source, null: false, index: true
      t.references :importer_log, null: false, index: true
      t.datetime :pre_processed_at, null: false
      t.string :source_hash
      t.references :source, null: false, index: false
      t.string :source_type, null: false
      t.timestamp :dirty_at
      t.timestamp :clean_at
      t.boolean :should_import, default: true
    end

    # Add indexes for importer table
    add_index :hmis_2026_custom_genders, [:PersonalID, :data_source_id], name: "idx_custom_genders_imp_id_ds"
    add_index :hmis_2026_custom_genders, [:source_type, :source_id], name: "idx_custom_genders_source"
  end
end
```

### Running the Migrations

After generation, run the migrations:

```bash
dcr shell bundle exec rails db:migrate
```

### Manual Migration Creation

If you need to create migrations manually, follow these patterns:

#### Key Points:
- **Loader tables**: All columns are strings (raw CSV data)
- **Importer tables**: Proper column types based on YAML configuration
- **Standard columns**: Always include the required framework columns
- **Indexes**: Add indexes for foreign keys and lookup columns

## Best Practices

1. **Use descriptive filenames**: `custom_gender.yaml`, `custom_assessment.yaml`
2. **Always validate required fields**: Use `required: true` and `validations: ["NonBlank"]`
3. **Be explicit about data types**: Use correct types (integer, string, date, datetime, boolean)
4. **Handle missing files gracefully**: Set `required: false` for optional files
5. **Generate and commit models**: Always run the bootstrap task after changing YAML files and commit the results
6. **Test thoroughly**: Create comprehensive tests for your custom files
7. **Document your additions**: Add comments explaining the purpose of each custom file

## Error Handling

The system handles various error conditions gracefully:

- **Missing YAML files**: Logged as warnings, bootstrap task may fail
- **Invalid YAML syntax**: Logged as errors, bootstrap task may fail
- **Missing CSV files**: Skipped if `required: false`
- **Invalid data**: Validation errors are logged, invalid records are skipped
- **Missing warehouse tables**: The bootstrap task will generate migrations to create them

## Performance Considerations

- **Batch processing**: Custom files are processed in batches like standard files
- **Index your tables**: Add appropriate indexes for foreign keys and lookup columns
- **Consider file size**: Very large custom files should use the same optimization patterns as standard files
- **Memory usage**: The system loads configuration once and caches it for performance

## Troubleshooting

### Common Issues

1. **Class not found errors**: Ensure you have run the bootstrap task after modifying YAML files and that the generated models are committed.
2. **Table doesn't exist**: Run the generated migrations.
3. **Validation errors**: Check your YAML configuration for typos in validation rules.
4. **Missing warehouse data**: Verify `augment_key` matches between CSV and warehouse table

### Debugging

Enable debug logging to see what's happening:

```ruby
Rails.logger.level = :debug
```

This will log:
- Which YAML files are being loaded
- Which classes are being used for processing
- Any errors in configuration parsing
