class CreateFormDefinitionFragments < ActiveRecord::Migration[7.0]
  def change
    create_table :hmis_form_definition_fragments do |t|
      t.timestamps
      t.string :identifier, null: false
      t.string :title
      t.jsonb :template, null: false
      t.datetime :deleted_at
      t.boolean :system_managed, default: false, null: false
      t.integer :version, null: false, default: 1
    end

    add_index :hmis_form_definition_fragments, [:identifier, :version],
              name: 'idx_hmis_form_definition_fragments_ident',
              unique: true
  end
end
