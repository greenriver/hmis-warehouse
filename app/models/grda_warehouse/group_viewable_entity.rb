###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Participates in both the "new" ACL permissions model and the "legacy" role-based model
# * A GroupViewableEntity a defines membership in a Collection.
# * Membership in a collection or access group are subject to the role permissions
# * records should have either an access_group_id or a collection_id but not both
module GrdaWarehouse
  class GroupViewableEntity < GrdaWarehouseBase
    acts_as_paranoid

    # records with a access_group_id are part of the "legacy" role-based permission system
    belongs_to :access_group, optional: true
    # records with a collection_id are part of the "new" access-control permission system
    belongs_to :entity, polymorphic: true
    belongs_to :collection, optional: true

    scope :viewable_by, ->(user) do
      where(access_group_id: user.access_groups.pluck(:id))
    end
  end
end
