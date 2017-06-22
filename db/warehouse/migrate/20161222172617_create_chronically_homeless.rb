class CreateChronicallyHomeless < ActiveRecord::Migration
  def up
    if GrdaWarehouseBase.connection.adapter_name == 'SQLServer'
      # create_table is broken for mssql
      GrdaWarehouseBase.connection.execute('create table chronics (id INT NOT NULL IDENTITY PRIMARY KEY )')
      change_table :chronics do |t|
        t.date :date, null: false, index: true
        t.references :client, null: false, index: true
        t.integer :days_in_last_three_years
        t.integer :months_in_last_three_years
        t.boolean :individual
        t.integer :age
        t.date :homeless_since
      end
    else
      create_table :chronics do |t|
        t.date :date, null: false, index: true
        t.references :client, null: false, index: true
        t.integer :days_in_last_three_years
        t.integer :months_in_last_three_years
        t.boolean :individual
        t.integer :age
        t.date :homeless_since
      end
    end
  end

  def down
    drop_table :chronics
  end
end
