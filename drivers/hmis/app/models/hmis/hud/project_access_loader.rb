###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::ProjectAccessLoader < Hmis::BaseAccessLoader
  # permissions check for a collection of tuples of [entity, permission]
  # note the same entity could appear more than once in items with different permissions
  # @param items [Array<Array<Hmis::Hud::Project, String>>]
  # @return [Array<Boolean>]
  def fetch(items)
    validate_items(items, Hmis::Hud::Project)
    project_ids = items.map { |i| i.first.id }.uniq

    access_group_ids_by_project_id = Hmis::Hud::Project
      .joins(:group_viewable_entities)
      .where(id: project_ids)
      .pluck(arel.p_t[:id], 'group_viewable_entities.access_group_id')
      .group_by(&:shift).transform_values(&:flatten)

    items.map do |item|
      project, permission = item
      access_group_ids = access_group_ids_by_project_id[project.id] || []
      user_access_groups_grant_permission?(access_group_ids, permission)
    end
  end
end
