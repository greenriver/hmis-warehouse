class AddOriginalResultsToReportResults < ActiveRecord::Migration[4.2]
  def change
    add_column :report_results, :original_results, :json
  end
end
