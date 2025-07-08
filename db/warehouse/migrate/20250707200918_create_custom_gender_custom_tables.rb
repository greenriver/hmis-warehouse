# frozen_string_literal: true

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
