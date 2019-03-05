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