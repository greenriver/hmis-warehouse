# frozen_string_literal: true

class CreateCustomDataElementDefinitionCustomTables < ActiveRecord::Migration[7.1]
  def change
    # CustomDataElementDefinition loader table
    create_table :hmis_csv_2026_custom_data_element_definitions do |t|
      t.string 'CustomDataElementDefinitionID'
      t.string 'Key'
      t.string 'RecordType'
      t.string 'FieldType'
      t.string 'Label'
      t.string 'Repeats'
      t.string 'DateCreated'
      t.string 'DateUpdated'
      t.string 'UserID'
      t.string 'DateDeleted'
      t.string 'ExportID'

      # Standard loader columns
      t.references :data_source, null: false, index: true
      t.datetime :loaded_at, null: false
      t.references :loader, null: false, index: true
    end

    # Add indexes for loader table
    add_index :hmis_csv_2026_custom_data_element_definitions, [:CustomDataElementDefinitionID, :data_source_id], name: 'idx_custom_data_element_definitions_id_ds'

    # CustomDataElementDefinition importer table
    create_table :hmis_2026_custom_data_element_definitions do |t|
      t.string 'CustomDataElementDefinitionID'
      t.string 'Key'
      t.string 'RecordType'
      t.string 'FieldType'
      t.string 'Label'
      t.boolean 'Repeats'
      t.datetime 'DateCreated'
      t.datetime 'DateUpdated'
      t.string 'UserID'
      t.datetime 'DateDeleted'
      t.string 'ExportID'

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
    add_index :hmis_2026_custom_data_element_definitions, [:CustomDataElementDefinitionID, :data_source_id], name: 'idx_custom_data_element_definitions_imp_id_ds'
    add_index :hmis_2026_custom_data_element_definitions, [:source_type, :source_id], name: 'idx_custom_data_element_definitions_source'
  end
end
