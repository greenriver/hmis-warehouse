###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  class GroupViewableEntity < GrdaWarehouseBase
    acts_as_paranoid

    belongs_to :access_group, optional: true
    belongs_to :entity, polymorphic: true
    belongs_to :collection, optional: true

    scope :viewable_by, ->(user) do
      where(access_group_id: user.access_groups.pluck(:id))
    end
  end
end
