class RemoveTeamFromTeamMembers < ActiveRecord::Migration[4.2][4.2]
  def change
    remove_column :team_members, :team_id, :integer
  end
end
