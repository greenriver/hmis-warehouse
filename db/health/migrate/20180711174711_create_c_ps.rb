class CreateCPs < ActiveRecord::Migration
  def change
    create_table :cps do |t|
      t.string :pid
      t.string :sl
      t.string :mmis_enrollment_name
      t.string :short_name
      t.string :pt_part_1
      t.string :pt_part_2
      t.string :address_1
      t.string :city
      t.string :state
      t.string :zip
      t.string :key_contact_first_name
      t.string :key_contact_last_name
      t.string :key_contact_email
      t.string :key_contact_phone
      t.boolean :sender, default: false, null: false
      t.string :receiver_name
      t.string :receiver_id
      t.timestamps
      t.datetime :deleted_at
    end
  end
end
