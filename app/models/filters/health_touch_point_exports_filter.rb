###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Filters
  class HealthTouchPointExportsFilter < DateRange
    attribute :name, String
    attribute :search_scope

    validates_presence_of :name

    def touch_points_for_user(user)
      return [] unless search_scope.present?

      @touch_points_for_user ||= search_scope.health_for_user(user).active.
        distinct.
        where(name: GrdaWarehouse::HmisForm.distinct.select(:name)).
        order(name: :asc).
        pluck(:name)
    end
  end
end
