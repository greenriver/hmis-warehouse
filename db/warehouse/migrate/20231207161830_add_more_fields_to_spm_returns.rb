class AddMoreFieldsToSpmReturns < ActiveRecord::Migration[6.1]
  def change
    add_column :hud_report_spm_returns, :project_type, :integer
  end
end
