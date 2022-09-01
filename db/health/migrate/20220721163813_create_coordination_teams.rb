class CreateCoordinationTeams < ActiveRecord::Migration[6.1]
  def change
    create_table :coordination_teams do |t|
      t.string :name
      t.string :color
      t.references :team_coordinator

      t.timestamps
    end

    add_reference :user_care_coordinators, :coordination_team
  end
end
