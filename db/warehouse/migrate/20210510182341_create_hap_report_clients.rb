class CreateHapReportClients < ActiveRecord::Migration[5.2]
  def change
    create_table :hap_report_clients do |t|
      t.references :client
      t.integer :age
      t.boolean :emancipated
      t.boolean :head_of_household
      t.string :household_ids, array: true
      t.integer :project_types, array: true
      t.boolean :veteran
      t.boolean :mental_health
      t.boolean :substance_abuse
      t.boolean :domestic_violence
      t.integer :income_at_start
      t.integer :income_at_exit
      t.boolean :homeless
      t.integer :nights_in_shelter

      t.datetime :deleted_at
      t.timestamps
    end
  end
end
