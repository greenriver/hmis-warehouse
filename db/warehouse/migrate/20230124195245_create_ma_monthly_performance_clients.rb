class CreateMaMonthlyPerformanceClients < ActiveRecord::Migration[6.1]
  def change
    create_table :ma_monthly_performance_clients do |t|
      t.references :report
      t.references :client
      t.references :project
      t.references :project_coc
      t.string :city
      t.string :coc_code
      t.date :entry_date, null: false
      t.date :exit_date, null: false
      t.boolean :latest_for_client
      t.boolean :chronically_homeless_at_entry
      t.integer :stay_length_in_days
      # TODO: demographics
      t.timestamps
    end
    create_table :ma_monthly_performance_projects do |t|
      t.references :project
      t.references :project_coc
      t.string :project_name
      t.string :organization_name
      t.string :coc_code
      t.date :month_start
      t.integer :available_beds
      t.integer :average_length_of_stay_in_days
      t.integer :number_chronically_homeless_at_entry
      t.string :city
      t.timestamps
    end
  end
end
