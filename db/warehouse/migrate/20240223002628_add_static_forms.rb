class AddStaticForms < ActiveRecord::Migration[6.1]
  def change
    create_table :hmis_static_forms do |t|
      t.timestamps
      t.string :name, null: false
      t.string :version, null: false
      t.jsonb :fields, null: false
      t.string :remote_location
    end
    add_index :hmis_static_forms, [:name, :version], name: 'uidx_hmis_static_forms', unique: true

    create_table :hmis_static_form_submissions do |t|
      t.timestamps
      t.datetime :submitted_at
      t.integer :spam_score
      t.string :status, null: false, default: 'new'
      t.string :form_name, null: false
      t.string :form_version, null: false
      t.string :remote_location
      t.jsonb :data, null: false
      t.text :notes
    end
    add_index :hmis_static_form_submissions, :remote_location, name: 'uidx_hmis_static_form_submissions', unique: true
  end
end
