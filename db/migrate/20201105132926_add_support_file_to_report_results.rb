class AddSupportFileToReportResults < ActiveRecord::Migration[5.2]
  def change
    add_column :report_results, :support_file_id, :integer
    add_column :report_results, :export_id, :integer
  end
end
