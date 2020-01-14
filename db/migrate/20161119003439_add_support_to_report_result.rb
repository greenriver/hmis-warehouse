class AddSupportToReportResult < ActiveRecord::Migration[4.2]
  def change
    add_column :report_results, :support, :json
  end
end
