class AddTimestampsToReportDefinitions < ActiveRecord::Migration[5.2]
  def change
    add_timestamps(:report_definitions, null: false, default: -> { 'NOW()' })
  end
end
