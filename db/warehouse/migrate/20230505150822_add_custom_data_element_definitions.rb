class AddCustomDataElementDefinitions < ActiveRecord::Migration[6.1]
  def up
    create_table :CustomDataElementDefinitions do |t|
      t.string :owner_type, null: false, comment: 'Record that this type of data element must be associated with'
      t.string :field_type, comment: 'Type of element (string, integer, etc)'
      t.string :key, comment: 'Machine-readable key for this type of data element. Will be used by the FormDefinition that collects/displays it.'
      t.string :label, comment: 'Human-readable label to use when displaying this type of data element.'
      t.boolean :repeats, null: false, default: false, comment: 'Whether multiple values are allowed per record.'
      t.datetime :deleted_at
      t.timestamps
    end
  end

  def down
    drop_table :CustomDataElementDefinitions
  end
end
