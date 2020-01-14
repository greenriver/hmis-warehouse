class AddTeamAndGoalArchivesToCareplan < ActiveRecord::Migration[4.2]
  def change
    add_column :careplans, :team_members_archive, :text
    add_column :careplans, :goals_archive, :text
  end
end
