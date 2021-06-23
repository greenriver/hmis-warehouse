class CreatePerformanceMetricsClients < ActiveRecord::Migration[5.2]
  def change
    create_table :performance_metrics_clients do |t|
      t.references :client

      t.jsonb :current_period_enrollments
      t.date :current_period_exit_date
      t.string :current_period_exit_project_name
      t.date :current_period_return_date
      t.string :current_period_return_project_name
      t.date :current_period_move_in_date
      t.string :current_period_move_in_project
      t.integer :current_period_days_in_es
      t.integer :current_period_days_in_rrh
      t.integer :current_period_days_in_psh
      t.integer :current_period_income_at_start
      t.integer :current_period_income_at_end
      t.integer :current_period_employment_income_at_start
      t.integer :current_period_employment_income_at_end
      t.integer :current_period_non_employment_income_at_start
      t.integer :current_period_non_employment_income_at_end
      t.boolean :current_period_first_time
      t.boolean :current_period_reentering
      t.references :current_period_caper
      t.references :current_period_spm

      t.jsonb :prior_period_enrollments
      t.date :prior_period_exit_date
      t.string :prior_period_exit_project_name
      t.date :prior_period_return_date
      t.string :prior_period_return_project_name
      t.date :prior_period_move_in_date
      t.string :prior_period_move_in_project
      t.integer :prior_period_days_in_es
      t.integer :prior_period_days_in_rrh
      t.integer :prior_period_days_in_psh
      t.integer :prior_period_income_at_start
      t.integer :prior_period_income_at_end
      t.integer :prior_period_employment_income_at_start
      t.integer :prior_period_employment_income_at_end
      t.integer :prior_period_non_employment_income_at_start
      t.integer :prior_period_non_employment_income_at_end
      t.boolean :prior_period_first_time
      t.boolean :prior_period_reentering
      t.references :prior_period_caper
      t.references :prior_period_spm

      t.timestamps index: true, null: false
      t.datetime :deleted_at, index: true
    end
  end
end
