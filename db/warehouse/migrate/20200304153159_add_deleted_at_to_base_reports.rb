class AddDeletedAtToBaseReports < ActiveRecord::Migration[5.2]
  def change
    add_column :warehouse_reports, :deleted_at, :datetime
  end
end
