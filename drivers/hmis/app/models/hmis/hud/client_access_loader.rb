###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
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

    group_view_t = Hmis::GroupViewableEntity.arel_table
    orphan_client_ids = Hmis::Hud::Client.
      left_outer_joins(:enrollments).
      where(id: client_ids).
      where(arel.e_t[:project_id].eq(nil)).
      pluck(arel.c_t[:id])

    access_group_ids_by_client_id = Hmis::Hud::Project.
      joins(:clients, :group_viewable_entities).
      where(arel.c_t[:id].in(client_ids - orphan_client_ids)).
      pluck(arel.c_t[:id], group_view_t[:collection_id]).
      group_by(&:shift).transform_values(&:flatten)

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
