
# frozen_string_literal: true

class AddHudFieldsToCustomDataElementDefinitions < ActiveRecord::Migration[7.1]
  def change
    add_column :CustomDataElementDefinitions, :CustomDataElementDefinitionID, :string
    add_column :CustomDataElementDefinitions, :ExportID, :string
    add_column :CustomDataElementDefinitions, :pending_date_deleted, :date
    add_column :CustomDataElementDefinitions, :source_hash, :string
    add_column :CustomDataElementDefinitions, :synthetic, :boolean, default: false

    safety_assured do
      # Make CustomDataElementDefinitionID unique when present (optional but unique if present)
      add_index :CustomDataElementDefinitions, [:data_source_id, :CustomDataElementDefinitionID], unique: true, where: '"CustomDataElementDefinitionID" IS NOT NULL'
    end
  end
end
