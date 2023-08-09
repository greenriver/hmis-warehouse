class ChangeVamcStationToString < ActiveRecord::Migration[6.1]
  # V6.1 list includes non-integer values such as '589A5'. Change it to a string col.
  def change
    view_maintainer = Bi::ViewMaintainer.new
    view_maintainer.remove_views
    add_column :Enrollment, :VAMCStation_new, :string, null: true
    GrdaWarehouse::Hud::Enrollment.where.not(VAMCStation: nil).update_all('"VAMCStation_new" = "VAMCStation"')
    rename_column :Enrollment, :VAMCStation, :VAMCStation_deleted
    rename_column :Enrollment, :VAMCStation_new, :VAMCStation
    view_maintainer.create_views
  end
end
