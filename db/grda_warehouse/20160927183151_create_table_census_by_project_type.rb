class CreateTableCensusByProjectType < ActiveRecord::Migration
  def change
    create_table :census_by_project_types do |t|
      t.integer :ProjectType, null: false
      t.date :date, null: false
      t.boolean :veteran, null: false, default: false
      t.integer :gender, null: false, default: 99   # 99 is "data not collected" per controlled vocabulary 3.6.1
      t.integer :client_count, null: false, default: 0
      t.integer :yesterdays_count, null: false, default: 0
    end
    add_index :censuses, [:date, :ProjectType]
  end
end
