class AddCustomClientAddressAndCustomClientContactPoint < ActiveRecord::Migration[6.1]
  def change
    create_table :CustomClientAddress do |t|
      t.string :use
      t.string :address_type
      t.string :line1
      t.string :line2
      t.string :city
      t.string :state
      t.string :district
      t.string :country
      t.string :postal_code
      t.string :notes
      t.string :AddressID, null: false
      t.string :PersonalID, null: false
      t.string :UserID, limit: 32, null: false
      t.integer :data_source_id
      t.datetime :DateCreated, null: false
      t.datetime :DateUpdated, null: false
      t.datetime :DateDeleted
    end

    create_table :CustomClientContactPoint do |t|
      t.string :use
      t.string :system
      t.string :value
      t.string :notes
      t.string :ContactPointID, null: false
      t.string :PersonalID, null: false
      t.string :UserID, limit: 32, null: false
      t.integer :data_source_id
      t.datetime :DateCreated, null: false
      t.datetime :DateUpdated, null: false
      t.datetime :DateDeleted
    end
  end
end
