class CreateHmisCaseNotes < ActiveRecord::Migration[6.1]
  def change
    add_column :Client, :preferred_name, :string, index: true
    add_column :Client, :pronouns, :string
    add_column :Client, :sexual_orientation, :string
    create_table :hmis_case_notes do |t|
      t.references :client, null: false, index: true
      t.references :user, null: false, index: true
      t.references :organization
      t.references :project
      t.references :enrollment
      t.references :source, polymorphic: true
      t.date :information_date, null: false
      t.text :note
      t.timestamps null: false
      t.datetime :deleted_at
    end

    create_table :hmis_client_alerts do |t|
      t.references :client, null: false, index: true
      t.references :user, null: false, index: true
      t.references :organization
      t.references :project
      t.string :coc_code
      t.references :source, polymorphic: true
      t.date :information_date, null: false
      t.string :severity, null: false
      t.text :note
      t.timestamps null: false
      t.datetime :deleted_at
    end

    create_table :hmis_wips do |t|
      t.references :client, null: false
      t.references :project
      t.references :enrollment
      t.references :source, polymorphic: true
      t.date :date, null: false
      t.jsonb :data
      t.timestamps null: false
      t.datetime :deleted_at
    end
  end
end
