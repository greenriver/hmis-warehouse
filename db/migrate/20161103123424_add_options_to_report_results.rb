class AddOptionsToReportResults < ActiveRecord::Migration
  def change
    add_column :report_results, :options, :json
  end
end
