class AddSupportToReportResult < ActiveRecord::Migration
  def change
    add_column :report_results, :support, :json
  end
end
