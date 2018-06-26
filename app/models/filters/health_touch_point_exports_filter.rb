module Filters
  class HealthTouchPointExportsFilter < DateRange
    attribute :name, String
    attribute :search_scope

    def touch_points_for_user user
      raise 'Search Scope required' unless search_scope
      @names ||= search_scope.health_for_user(user).active.
        distinct.
        where(name: GrdaWarehouse::HmisForm.distinct.select(:name)).
        order(name: :asc).
        pluck(:name)
    end
  end
end