class CreateHmisRoles < ActiveRecord::Migration[6.1]
  def change
    create_table :hmis_roles do |t|
      t.string :name, null: false
      t.boolean :can_view_full_ssn, default: false, null: false
      t.boolean :can_view_clients, default: false, null: false
      t.timestamps
      t.datetime :deleted_at
    end

    create_table :user_hmis_data_source_roles do |t|
      t.references :user, null: false
      t.references :role, null: false
      t.references :data_source, null: false
      t.timestamps
      t.datetime :deleted_at
    end
  end
end
