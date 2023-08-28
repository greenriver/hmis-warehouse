class CopyOverVamcColumn < ActiveRecord::Migration[6.1]
  def change
    GrdaWarehouse::Hud::Enrollment.where.not(VAMCStation: nil).update_all('"VAMCStation_new" = "VAMCStation"')
  end
end
