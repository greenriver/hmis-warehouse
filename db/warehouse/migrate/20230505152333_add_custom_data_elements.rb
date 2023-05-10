class AddCustomDataElements < ActiveRecord::Migration[6.1]
  def up
    drop_table :CustomFormAnswers

    create_table :CustomDataElements do |t|
      t.references :data_element_definition, null: false, comment: 'Definition for this data element'
      t.references :owner, null: false, polymorphic: true, comment: 'Record that this data element belongs to (Client, Project, CustomAssessment, etc)'
      t.float :value_float
      t.integer :value_integer
      t.boolean :value_boolean
      t.string :value_string
      t.text :value_text
      t.date :value_date
      t.jsonb :value_json

      # HUD fields
      t.integer :data_source_id
      t.string :UserID, limit: 32, null: false
      t.datetime :DateCreated, null: false
      t.datetime :DateUpdated, null: false
      t.datetime :DateDeleted
    end
  end

  def down
    drop_table :CustomDataElements
  end
end
