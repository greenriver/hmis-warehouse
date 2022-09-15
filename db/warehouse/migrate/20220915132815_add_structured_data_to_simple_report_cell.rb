class AddStructuredDataToSimpleReportCell < ActiveRecord::Migration[6.1]
  def change
    add_column :simple_report_cells, :structured_data, :jsonb
  end
end
