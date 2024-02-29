class AddStaticForms < ActiveRecord::Migration[6.1]
  def change
    create_table :hmis_static_form_definition do |t|
      t.timestamps
      t.string :name, null: false, index: {unique: true}
      t.string :title, null: false
      t.jsonb :data, null: false
      t.text :content
      t.string :content_digest
      t.string :object_key
    end

    create_table :hmis_static_form_submissions do |t|
      t.timestamps
      t.datetime :submitted_at
      t.float :spam_score
      t.string :status, null: false, default: 'new'
      t.references :form_definition, null: false
      t.string :object_key, null: false
      t.jsonb :data, null: false
      t.text :notes
    end
  end
end
