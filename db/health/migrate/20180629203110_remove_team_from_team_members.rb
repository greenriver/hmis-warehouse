class RemoveTeamFromTeamMembers < ActiveRecord::Migration
  def change
    remove_column :team_members, :team_id, :integer
  end
end
