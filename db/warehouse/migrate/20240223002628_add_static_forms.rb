class AddStaticForms < ActiveRecord::Migration[6.1]
  def change
    create_table :hmis_static_forms do |t|
      t.timestamps
      t.string :name, null: false
      t.string :content_version, null: false
      t.text :content, null: false
      t.jsonb :form_definition, null: false
      t.string :object_key, index: { unique: true }
    end
    add_index :hmis_static_forms, [:name, :content_version], name: 'uidx_hmis_static_forms', unique: true

    create_table :hmis_static_form_submissions do |t|
      t.timestamps
      t.datetime :submitted_at
      t.float :spam_score
      t.string :status, null: false, default: 'new'
      t.string :form_content_version, null: false, index: true
      t.string :object_key, index: { unique: true }
      t.jsonb :data, null: false
      t.text :notes
    end
  end
end
