class AddLimitableToReportDefinitions < ActiveRecord::Migration[4.2]
  def change
    add_column :report_definitions, :limitable, :boolean, default: true, null: false
  end
end
