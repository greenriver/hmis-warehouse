class AddTeamCoordinatorRole < ActiveRecord::Migration[4.2][4.2]
  def up
    Role.create(name: 'Team Coordinator', health_role: true, can_manage_care_coordinators: true)
  end
end
