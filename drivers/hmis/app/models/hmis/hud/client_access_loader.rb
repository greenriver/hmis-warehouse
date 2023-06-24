###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::ClientAccessLoader < Hmis::BaseAccessLoader
  # permissions check for a collection of tuples of [entity, permission]
  # note the same entity could appear more than once in items with different permissions
  # @param items [Array<Array<Hmis::Hud::Client, String>>]
  # @return [Array<Boolean>]
  def fetch(items)
    validate_items(items, Hmis::Hud::Client)
    client_ids = items.map { |i| i.first.id }.compact.uniq

    orphan_client_ids = Hmis::Hud::Client
      .left_outer_joins(:client_projects)
      .where(id: client_ids)
      .where(client_projects: { project_id: nil })
      .pluck(arel.c_t[:id])

    access_group_ids_by_client_id = Hmis::Hud::Project
      .joins(:client_projects, :group_viewable_entities)
      .where(client_projects: { client_id: client_ids - orphan_client_ids })
      .pluck('client_projects.client_id', 'group_viewable_entities.access_group_id')
      .group_by(&:shift).transform_values(&:flatten)

    orphan_client_ids = orphan_client_ids.to_set
    items.map do |item|
      client, permission = item
      if client.persisted? ? client.id.in?(orphan_client_ids) : client.enrollments.empty?
        # client is not associated with a project, grant permission
        user.permission?(permission)
      else
        access_group_ids = access_group_ids_by_client_id[client.id] || []
        user_access_groups_grant_permission?(access_group_ids, permission)
      end
    end
  end
end
