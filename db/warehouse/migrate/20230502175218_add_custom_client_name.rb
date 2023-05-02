class AddCustomClientName < ActiveRecord::Migration[6.1]
  def change
    create_table :CustomClientName do |t|
      t.string :first
      t.string :middle
      t.string :last
      t.string :suffix
      t.string :use
      t.text :notes
      t.boolean :primary
      t.integer :NameDataQuality
      t.string :CustomClientNameID, null: false
      t.string :PersonalID, null: false
      t.string :UserID, limit: 32, null: false
      t.integer :data_source_id
      t.datetime :DateCreated, null: false
      t.datetime :DateUpdated, null: false
      t.datetime :DateDeleted
    end

    add_index :CustomClientName, [:primary, :PersonalID, :data_source_id], unique: true, name: 'unique_index_ensuring_one_primary_per_client'
  end
end
