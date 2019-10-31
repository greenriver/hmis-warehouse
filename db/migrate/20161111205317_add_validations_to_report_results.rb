class AddValidationsToReportResults < ActiveRecord::Migration[4.2]
  def change
    add_column :report_results, :validations, :json
  end
end
