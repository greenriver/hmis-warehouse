module Filters
  class DateRangeAndProject < DateRange
    attribute :project_type, Array[String]

    def project_types
      GrdaWarehouse::Hud::Project::HOMELESS_TYPE_TITLES.map(&:reverse)
    end
  end
end