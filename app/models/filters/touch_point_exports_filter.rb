###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Filters
  class TouchPointExportsFilter < DateRange
    attribute :name, String
    attribute :search_scope

    def touch_points_for_user user
      return [] unless search_scope.present?
      @names ||= search_scope.for_user(user).active.
        distinct.
        where(name: GrdaWarehouse::HmisForm.distinct.select(:name)).
        order(name: :asc).
        pluck(:name)
    end
  end
end