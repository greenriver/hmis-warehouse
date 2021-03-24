class AddPrecalculatedDataToPublicReports < ActiveRecord::Migration[5.2]
  def change
    add_column :public_report_reports, :precalculated_data, :text
  end
end
