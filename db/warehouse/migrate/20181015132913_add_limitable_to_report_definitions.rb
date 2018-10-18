class AddLimitableToReportDefinitions < ActiveRecord::Migration
  def change
    add_column :report_definitions, :limitable, :boolean, default: true, null: false
  end
end
