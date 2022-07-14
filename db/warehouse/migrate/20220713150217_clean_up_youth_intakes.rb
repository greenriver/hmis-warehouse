class CleanUpYouthIntakes < ActiveRecord::Migration[6.1]
  def change
    PaperTrail.enabled = false
    GrdaWarehouse::YouthIntake::Base.with_deleted.find_each do |intake|
      client_race = intake.client_race.reject(&:blank?)
      client_race = ['RaceNone'] if client_race.nil? || client_race.size.zero?
      disabilities = intake.disabilities.reject(&:blank?)
      disabilities = ['Unknown'] if disabilities.nil? || disabilities.size.zero?
      other_agency_involvements = intake.other_agency_involvements.reject(&:blank?)
      other_agency_involvements = ['Unknown'] if other_agency_involvements.nil? || other_agency_involvements.size.zero?

      intake.update(client_race: client_race, disabilities: disabilities, other_agency_involvements: other_agency_involvements)
    end
  end
end
