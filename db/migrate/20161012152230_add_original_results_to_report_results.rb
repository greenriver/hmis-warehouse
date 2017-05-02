class AddOriginalResultsToReportResults < ActiveRecord::Migration
  def change
    add_column :report_results, :original_results, :json
  end
end
