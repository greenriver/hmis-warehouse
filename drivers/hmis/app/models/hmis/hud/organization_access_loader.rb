###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::OrganizationAccessLoader < Hmis::BaseAccessLoader
  # permissions check for a collection of tuples of [entity, permission]
  # note the same entity could appear more than once in items with different permissions
  # @param items [Array<Array<Hmis::Hud::Organization, String>>]
  # @return [Array<Boolean>]
  def fetch(items)
    validate_items(items, Hmis::Hud::Organization)
    organization_ids = items.map { |i| i.first.id }.compact.uniq

    access_group_ids_by_organization_id = Hmis::Hud::Organization.
      where(id: organization_ids).
      joins(:group_viewable_entities).
      pluck(arel.o_t[:id], 'hmis_group_viewable_entities.collection_id').
      group_by(&:shift).transform_values(&:flatten)

    items.map do |item|
      organization, permission = item
      if organization.persisted?
        access_group_ids = access_group_ids_by_organization_id[organization.id] || []
        user_access_groups_grant_permission?(access_group_ids, permission)
      else
        false
      end
    end
  end
end
