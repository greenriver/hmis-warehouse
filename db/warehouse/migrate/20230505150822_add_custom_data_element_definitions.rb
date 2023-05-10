class AddCustomDataElementDefinitions < ActiveRecord::Migration[6.1]
  def up
    create_table :CustomDataElementDefinitions do |t|
      # Describe what this custom field should be associated with
      t.string :owner_type, null: false, index: true, comment: 'Record that this type of data element must be associated with'
      t.references :custom_service_type, index: true, comment: 'Service type that this type of data element must be associated with'

      # Describe what this custom field should look like
      t.string :field_type, comment: 'Type of element (string, integer, etc)'
      t.string :key, comment: 'Machine-readable key for this type of data element. Will be used by the FormDefinition that collects/displays it.'
      t.string :label, comment: 'Human-readable label to use when displaying this type of data element.'
      t.boolean :repeats, null: false, default: false, comment: 'Whether multiple values are allowed per record.'

      # HUD fields
      t.integer :data_source_id
      t.string :UserID, limit: 32, null: false
      t.datetime :DateCreated, null: false
      t.datetime :DateUpdated, null: false
      t.datetime :DateDeleted
    end
  end

  def down
    drop_table :CustomDataElementDefinitions
  end
end
