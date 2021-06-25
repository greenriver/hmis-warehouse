class CreatePerformanceMetricsClients < ActiveRecord::Migration[5.2]
  def change
    create_table :performance_metrics_clients do |t|
      t.references :client

      t.integer :current_period_age
      t.integer :current_period_earned_income_at_start
      t.integer :current_period_earned_income_at_exit
      t.integer :current_period_other_income_at_start
      t.integer :current_period_other_income_at_exit
      t.integer :current_period_days_in_es
      t.integer :current_period_days_in_rrh
      t.integer :current_period_days_in_psh
      t.boolean :current_period_first_time
      t.boolean :current_period_reentering
      t.boolean :current_period_in_outflow
      t.boolean :current_period_entering_housing
      t.boolean :current_period_inactive
      t.references :current_period_caper
      t.references :current_period_spm

      t.integer :prior_period_age
      t.integer :prior_period_earned_income_at_start
      t.integer :prior_period_earned_income_at_exit
      t.integer :prior_period_other_income_at_start
      t.integer :prior_period_other_income_at_exit
      t.integer :prior_period_days_in_es
      t.integer :prior_period_days_in_rrh
      t.integer :prior_period_days_in_psh
      t.boolean :prior_period_first_time
      t.boolean :prior_period_reentering
      t.boolean :prior_period_in_outflow
      t.boolean :prior_period_entering_housing
      t.boolean :prior_period_inactive
      t.references :prior_period_caper
      t.references :prior_period_spm

      t.timestamps index: true, null: false
      t.datetime :deleted_at, index: true
    end
  end
end
