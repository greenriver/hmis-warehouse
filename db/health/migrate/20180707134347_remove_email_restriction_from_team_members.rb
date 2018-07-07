class RemoveEmailRestrictionFromTeamMembers < ActiveRecord::Migration
  def change
    change_column :team_members, :email, :string, null: true
  end
end
