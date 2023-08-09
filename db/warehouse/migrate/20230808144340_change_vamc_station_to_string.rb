class ChangeVamcStationToString < ActiveRecord::Migration[6.1]
  def up
    # V6.1 list includes non-integer values such as '589A5'
    add_column :Enrollment, :VAMCStation_new, :string, null: true
    GrdaWarehouse::Hud::Enrollment.update_all('VAMCStation_new = VAMCStation')
    remove_column :Enrollment, :VAMCStation, :integer, null: true
    rename_column :Enrollment, :VAMCStation_new, :VAMCStation
  end

  def down
    change_column :Enrollment, :VAMCStation, :integer
  end
end
