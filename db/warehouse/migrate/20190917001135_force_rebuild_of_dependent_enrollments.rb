class ForceRebuildOfDependentEnrollments < ActiveRecord::Migration[4.2]
  def up
    GrdaWarehouse::Hud::Enrollment.where.not(RelationshipToHoH: [1, nil]).update_all(processed_as: nil)
  end
end
