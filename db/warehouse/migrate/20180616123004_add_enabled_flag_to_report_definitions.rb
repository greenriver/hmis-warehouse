class AddEnabledFlagToReportDefinitions < ActiveRecord::Migration
  def change
    add_column :report_definitions, :enabled, :boolean, null: false, default: true
  end
end
