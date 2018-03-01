module Filters
  class TouchPointExportsFilter < DateRange
    attribute :name, String

    def names
      @names ||= GrdaWarehouse::HMIS::Assessment.non_confidential.active.
        distinct.
        where(name: GrdaWarehouse::HmisForm.distinct.select(:name)).
        order(name: :asc).
        pluck(:name)
    end
  end
end