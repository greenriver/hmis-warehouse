class AddOptionsToReportResults < ActiveRecord::Migration[4.2]
  def change
    add_column :report_results, :options, :json
  end
end
