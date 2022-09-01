class MigrateCoordinationTeams < ActiveRecord::Migration[6.1]
  def change
    care_coordinator_ids = Health::UserCareCoordinator.pluck(:care_coordinator_id).uniq
    care_coordinator_ids.each_with_index do |cc_id, index|
      team = Health::CoordinationTeam.create(name: "Team #{index + 1}", team_coordinator_id: cc_id)
      Health::UserCareCoordinator.where(care_coordinator_id: cc_id).find_each do |association|
        association.update(coordination_team: team)
      end
    end
  end
end
