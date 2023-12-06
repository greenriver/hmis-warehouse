class AddFieldsToSpmReturns < ActiveRecord::Migration[6.1]
  def change
    StrongMigrations.disable_check(:add_reference)
    
    add_reference :hud_report_spm_returns, :report_instance
    add_column :hud_report_spm_returns, :days_to_return, :integer

  ensure
    StrongMigrations.enable_check(:add_reference)
  end
end
