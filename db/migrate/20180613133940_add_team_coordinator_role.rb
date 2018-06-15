class AddTeamCoordinatorRole < ActiveRecord::Migration
  def up
    Role.create(name: 'Team Coordinator', health_role: true, can_manage_care_coordinators: true)
  end
end
