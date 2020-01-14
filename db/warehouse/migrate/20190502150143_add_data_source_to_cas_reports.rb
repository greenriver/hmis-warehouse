class AddDataSourceToCasReports < ActiveRecord::Migration[4.2]
  def change
    add_column :cas_reports, :source_data_source, :string
  end
end
