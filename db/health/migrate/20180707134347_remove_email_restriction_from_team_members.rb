class RemoveEmailRestrictionFromTeamMembers < ActiveRecord::Migration[4.2]
  def change
    change_column :team_members, :email, :string, null: true
  end
end
