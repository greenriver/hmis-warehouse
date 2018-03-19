module Filters
  class TouchPointExportsFilter < DateRange
    attribute :name, String

    def touch_points_for_user user
      @names ||= GrdaWarehouse::HMIS::Assessment.for_user(user).active.
        distinct.
        where(name: GrdaWarehouse::HmisForm.distinct.select(:name)).
        order(name: :asc).
        pluck(:name)
    end
  end
end