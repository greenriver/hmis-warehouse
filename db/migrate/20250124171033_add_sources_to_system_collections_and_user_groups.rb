class AddSourcesToSystemCollectionsAndUserGroups < ActiveRecord::Migration[7.0]
  def up
    GrdaWarehouse::ProjectGroup.find_each(&:fix_entity_associations)
    GrdaWarehouse::Cohort.find_each(&:fix_entity_associations)
  end
end
