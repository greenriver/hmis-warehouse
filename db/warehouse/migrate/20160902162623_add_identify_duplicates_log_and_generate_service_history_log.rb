class AddIdentifyDuplicatesLogAndGenerateServiceHistoryLog < ActiveRecord::Migration
  def change
    create_table :identify_duplicates_log do |t|
      t.datetime :started_at
      t.datetime :completed_at
      t.integer :to_match
      t.integer :matched
      t.integer :new_created

      t.timestamps null: false
    end
    create_table :generate_service_history_log do |t|
      t.datetime :started_at
      t.datetime :completed_at
      t.integer :to_delete
      t.integer :to_add
      t.integer :to_update

      t.timestamps null: false
    end
  end
end
