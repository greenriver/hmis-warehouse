class AddExternalForms < ActiveRecord::Migration[6.1]
  def change
    add_column :hmis_form_definitions, :external_form_object_key, :string
    add_column 'CustomDataElementDefinitions', :form_definition_identifier, :string
    safety_assured do
      add_index 'CustomDataElementDefinitions', :form_definition_identifier, name: 'idx_CustomDataElementDefinitions_1'
      add_index :hmis_form_definitions, [:external_form_object_key], unique: true
    end

    create_table :hmis_external_form_publications do |t|
      t.timestamps
      t.references :definition, null: false
      t.string :object_key, null: false
      t.jsonb :content_definition, null: false
      t.text :content
      t.string :content_digest
    end

    create_table :hmis_external_form_submissions do |t|
      t.timestamps
      t.datetime :submitted_at
      t.float :spam_score
      t.string :status, null: false, default: 'new'
      t.references :definition, null: false
      t.string :object_key, null: false
      t.jsonb :raw_data, null: false
      t.text :notes
    end
  end
end
