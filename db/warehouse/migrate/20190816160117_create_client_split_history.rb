class CreateClientSplitHistory < ActiveRecord::Migration[4.2]
  def change
    create_table :client_split_histories do |t|
      t.integer :split_into, null: false
      t.integer :split_from, null: false, index: true
      t.timestamps null: false, index: true
    end
  end
end
