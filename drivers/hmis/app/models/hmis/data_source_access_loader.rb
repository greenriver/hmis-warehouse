###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::DataSourceAccessLoader < Hmis::BaseAccessLoader
  # permissions check for a collection of tuples of [entity, permission]
  # note the same entity could appear more than once in items with different permissions
  # @param items [Array<Array<GrdaWarehouse::DataSource, String>>]
  # @return [Array<Boolean>]
  def fetch(items)
    validate_items(items, GrdaWarehouse::DataSource)
    entity_ids = items.map { |i| i.first.id }.compact.uniq

    access_group_ids_by_client_id = Hmis::GroupViewableEntity.data_sources
      .where(entity_id: entity_ids)
      .pluck('group_viewable_entities.entity_id', 'group_viewable_entities.access_group_id')
      .group_by(&:shift).transform_values(&:flatten)

    items.map do |entity, permission|
      access_group_ids = access_group_ids_by_client_id[entity.id] || []
      user_access_groups_grant_permission?(access_group_ids, permission)
    end
  end
end
