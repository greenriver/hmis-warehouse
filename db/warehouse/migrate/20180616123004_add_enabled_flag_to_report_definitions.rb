class AddEnabledFlagToReportDefinitions < ActiveRecord::Migration[4.2]
  def change
    add_column :report_definitions, :enabled, :boolean, null: false, default: true
  end
end
