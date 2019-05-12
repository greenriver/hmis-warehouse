class AddDataSourceToCasReports < ActiveRecord::Migration
  def change
    add_column :cas_reports, :source_data_source, :string
  end
end
