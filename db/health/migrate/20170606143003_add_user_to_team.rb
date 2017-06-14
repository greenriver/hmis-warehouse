class AddUserToTeam < ActiveRecord::Migration
  def change
    add_column :teams, :user_id, :integer, index: true
    add_column :team_members, :user_id, :integer, index: true
  end
end
