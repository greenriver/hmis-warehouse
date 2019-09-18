class ForceRebuildOfDependentEnrollments < ActiveRecord::Migration
  def up
    GrdaWarehouse::Hud::Enrollment.where.not(RelationshipToHoH: [1, nil]).update_all(processed_as: nil)
  end
end
