class AddPatientRefToTeamMembers < ActiveRecord::Migration[4.2][4.2]
  def change
    add_reference :team_members, :patient, index: true, foreign_key: true
  end
end
