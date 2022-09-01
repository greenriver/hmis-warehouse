class AddNcmToCoordinationTeams < ActiveRecord::Migration[6.1]
  def change
    add_reference :coordination_teams, :team_nurse_care_manager
  end
end
