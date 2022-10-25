class CreateCoCPitCounts < ActiveRecord::Migration[6.1]
  def change
    create_table :coc_pit_counts do |t|
      t.references :goal
      t.date :pit_date
      t.integer :sheltered
      t.integer :unsheltered

      t.timestamps
      t.datetime :deleted_at
    end
  end
end
