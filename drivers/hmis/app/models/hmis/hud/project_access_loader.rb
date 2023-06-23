###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::ProjectAccessLoader < Hmis::BaseAccessLoader
  # permissions check for a collection of tuples of [entity, permission]
  # note the same entity could appear more than once in items with different permissions
  # @param items Array<Array<Hmis::Hud::Project, String>>
  # @return Array<Boolean>
  def fetch(items)
    project_ids = items.map { |i| i.first.id }

    access_group_ids_by_project_id = Hmis::Hud::Project
      .joins(:group_viewable_entities)
      .where(id: project_ids)
      .pluck('Project.id', 'group_viewable_entities.access_group_id')
      .group_by(&:first)
      .transform_values(&:last)

    roles_by_access_group_id = user.roles
      .joins(:access_controls)
      .select('hmis_roles.*, hmis_access_controls.access_group_id AS access_group_id')
      .group_by(&:access_group_id)

    items.each do |item|
      project, permission = item
      access_group_ids = access_group_ids_by_project_id[project.id]
      access_group_ids.detect do |access_group_id|
        (roles_by_access_group_id[access_group_id] || []).detect do |role|
          role.grants?(permission)
        end
      end
    end
  end
end
