class CareTeamUpdates < ActiveRecord::Migration[4.2][4.2]
  def change
    add_reference :teams, :careplan, index: true
    add_column :team_members, :phone, :string
  end
end
