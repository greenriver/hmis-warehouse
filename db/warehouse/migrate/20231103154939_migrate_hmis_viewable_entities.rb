class MigrateHmisViewableEntities < ActiveRecord::Migration[6.1]
  def change
    # Migrate records from GrdaWarehouse::GroupViewableEntity to Hmis::GroupViewableEntity
    # NOTE: this only migrates Viewable Entities for Projects and Organiations.
    # If there were any HMIS AccesGroups that contained _data sources_, they will need to
    # be manually updated in the UI.

    entity_types = [
      'Hmis::Hud::Organization',
      'Hmis::Hud::Project',
    ]
    rows_to_migrate = GrdaWarehouse::GroupViewableEntity.where(entity_type: entity_types)
    if rows_to_migrate.exists?
      attributes = rows_to_migrate.map do |gve|
        {
          collection_id: gve.access_group_id,
          entity_id: gve.entity_id,
          entity_type: gve.entity_type,
        }
      end

      Hmis::GroupViewableEntity.transaction do
        result = Hmis::GroupViewableEntity.import(attributes)
        raise "Failed to import HMIS group viewable entities: #{result.failed_instances}" if result.failed_instances.any?

        # Delete from warehouse table
        # Commenting out, we can do this later after verifying a successful migration
        # rows_to_migrate.update_all(deleted_at: Time.current)
      end
    end
  end
end
