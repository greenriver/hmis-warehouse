module Filters
  class TouchPointExportsFilter < DateRange
    attribute :name, String

    def names
      @names ||= GrdaWarehouse::HmisForm.select(:name)
        .distinct
        .order(name: :asc)
        .pluck(:name)
    end
  end
end