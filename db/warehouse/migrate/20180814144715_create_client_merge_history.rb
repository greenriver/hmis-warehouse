class CreateClientMergeHistory < ActiveRecord::Migration[4.2]
  def change
    create_table :client_merge_histories do |t|
      t.integer :merged_into, null: false
      t.integer :merged_from, null: false, index: true
      t.timestamps null: false, index: true
    end
  end
end
