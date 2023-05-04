class RenameActiveRangeColumns < ActiveRecord::Migration[6.1]
  def change
    rename_column :hmis_active_ranges, :start, :start_date
    rename_column :hmis_active_ranges, :end, :end_date
  end
end
