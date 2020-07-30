class CopyYouthIntakeAgenciesToArray < ActiveRecord::Migration[5.2]
  def up
    PaperTrail.enabled = false
    GrdaWarehouse::YouthIntake::Base.find_each do |intake|
      intake.update_columns(other_agency_involvements: [intake&.other_agency_involvement])
    end
  end
end
