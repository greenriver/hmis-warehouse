class CopyYouthIntakeAgenciesToArray < ActiveRecord::Migration[5.2]
  def change
    PaperTrail.enabled = false
    GrdaWarehouse::YouthIntake::Base.find_each do |intake|
      intake.update(other_agency_involvements: [intake.other_agency_involvement])
    end
  end
end
