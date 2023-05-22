class MakeReportDefinitionsParanoid < ActiveRecord::Migration[6.1]
  def change
    add_column :report_definitions, :deleted_at, :datetime
  end
end
