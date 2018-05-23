class CareTeamUpdates < ActiveRecord::Migration
  def change
    add_reference :teams, :careplan, index: true
    add_column :team_members, :phone, :string
  end
end
