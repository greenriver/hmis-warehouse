class AddCollectionToGroupViewableEntities < ActiveRecord::Migration[6.1]
  def change
    StrongMigrations.disable_check(:add_reference)
    add_reference :group_viewable_entities, :collection
  ensure
    StrongMigrations.enable_check(:add_reference)
  end
end
