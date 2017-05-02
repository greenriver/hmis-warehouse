class AddValidationsToReportResults < ActiveRecord::Migration
  def change
    add_column :report_results, :validations, :json
  end
end
