class ChangeVamcStationToString < ActiveRecord::Migration[6.1]
  def up
    # V6.1 list includes non-integer values such as '589A5'
    change_column :Enrollment, :VAMCStation, :string
  end

  def down
    change_column :Enrollment, :VAMCStation, :integer
  end
end
