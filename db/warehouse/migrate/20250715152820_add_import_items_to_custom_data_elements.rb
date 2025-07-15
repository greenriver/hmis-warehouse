class AddImportItemsToCustomDataElements < ActiveRecord::Migration[7.1]
  def change
    add_column :CustomDataElements, :CustomDataElementID, :string
    add_column :CustomDataElements, :CustomDataElementDefinitionID, :string
    add_column :CustomDataElements, :DataCollectionStage, :integer
    add_column :CustomDataElements, :InformationDate, :date
    add_column :CustomDataElements, :ExportID, :string
    add_column :CustomDataElements, :pending_date_deleted, :date
    add_column :CustomDataElements, :source_hash, :string
    add_column :CustomDataElements, :synthetic, :boolean, default: false

    safety_assured do
      # Make CustomDataElementID unique when present (optional but unique if present)
      add_index :CustomDataElements, [:data_source_id, :CustomDataElementID], unique: true, where: '"CustomDataElementID" IS NOT NULL'
    end
  end
end
