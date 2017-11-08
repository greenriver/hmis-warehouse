class CreateHudChronics < ActiveRecord::Migration
  def change
    create_table :hud_chronics do |t|
      t.date :date
      t.references :client, index: true
      t.integer :months_in_last_three_years
      t.boolean :individual
      t.integer :age
      t.date :homeless_since
      t.boolean :dmh
      t.string :trigger
      t.string :project_names

      t.timestamps null: false
    end
  end
end
