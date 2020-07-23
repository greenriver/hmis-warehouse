class TestClasses < ActiveRecord::Migration[5.2]
  def change
    create_table :test_people do |t|
      t.string :encrypted_first_name
      t.string :encrypted_first_name_iv
      t.string :email
      t.string :hair
    end

    create_table :test_clients do |t|
      t.string :FirstName
      t.string :encrypted_FirstName
      t.string :encrypted_FirstName_iv
    end

    create_table :test_addresses do |t|
      t.integer :test_person_id
      t.string :street
    end
  end
end
