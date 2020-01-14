class SoEnrollmentFlagResetCache < ActiveRecord::Migration[4.2]
  def change
    GrdaWarehouse::Config.invalidate_cache
    GrdaWarehouse::Config.first.update(so_day_as_month: true)
  end
end
