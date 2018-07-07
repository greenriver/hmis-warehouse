class AddPatientRefToTeamMembers < ActiveRecord::Migration
  def change
    add_reference :team_members, :patient, index: true, foreign_key: true
  end
end
