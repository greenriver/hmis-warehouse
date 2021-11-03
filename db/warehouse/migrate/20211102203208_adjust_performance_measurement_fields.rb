class AdjustPerformanceMeasurementFields < ActiveRecord::Migration[5.2]
  def change
    add_column :pm_clients, :reporting_days_homeless_es_sh_th_ph, :integer

    add_column :pm_client_projects, :report_id, :integer
    add_column :pm_client_projects, :for_question, :string
    add_column :pm_client_projects, :period, :string
    remove_column :pm_client_projects, :reporting_period, :boolean
    remove_column :pm_client_projects, :comparison_period, :boolean

    add_column :pm_projects, :project_id, :integer
    add_column :pm_projects, :period, :string
    remove_column :pm_projects, :reporting_period, :boolean
    remove_column :pm_projects, :comparison_period, :boolean

    add_column :hud_report_spm_clients, :m3_history, :jsonb
  end
end
