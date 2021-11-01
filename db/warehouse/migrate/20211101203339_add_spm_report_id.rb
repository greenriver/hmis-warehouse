class AddSpmReportId < ActiveRecord::Migration[5.2]
  def change
    add_column :pm_clients, :reporting_spm_id, :integer
    add_column :pm_clients, :comparison_spm_id, :integer
  end
end
