class CreateCustomImportsBContactsRows < ActiveRecord::Migration[5.2]
  def change
    create_table :custom_imports_b_contacts_rows do |t|
      t.references :import_file
      t.references :data_source
      t.integer :row_number, null: false
      t.string :personal_id, null: false
      t.string :unique_id
      t.string :agency_id, null: false
      t.string :contact_name
      t.string :contact_type
      t.string :phone
      t.string :phone_alternate
      t.string :email
      t.string :note
      t.string :private
      t.datetime :contact_created_at
      t.datetime :contact_updated_at
      t.timestamps null: false, index: true
    end

    create_table :client_contacts do |t|
      t.references :client, null: false, index: true
      t.references :source, polymorphic: true, null: false, index: true
      t.string :first_name
      t.string :last_name
      t.string :full_name
      t.string :contact_type
      t.string :phone
      t.string :phone_alternate
      t.string :email
      t.string :address
      t.string :address2
      t.string :city
      t.string :state
      t.string :zip
      t.string :note
      t.datetime :last_modified_at

      t.timestamps null: false
    end
  end
end
