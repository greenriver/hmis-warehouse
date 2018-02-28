class FixShPresentedAsIndividual < ActiveRecord::Migration
  def up
    # # Set all to true
    # GrdaWarehouse::ServiceHistory.update_all(presented_as_individual: true)
    # # Set family enrollments to false
    # GrdaWarehouse::ServiceHistory.joins(:project).merge(GrdaWarehouse::Hud::Project.serves_families).update_all(presented_as_individual: false)

  end
end
