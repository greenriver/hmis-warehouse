class AddSoEnrollmentFlag < ActiveRecord::Migration
  def change
    unless GrdaWarehouse::Config.column_names.include?('so_day_as_month')
      add_column :configs, :so_day_as_month, :boolean, default: true
    end
  end
end
