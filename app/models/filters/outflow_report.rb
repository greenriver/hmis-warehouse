###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

# provides validation for date ranges
module Filters
  class OutflowReport < DateRangeAndSources
    attribute :sub_population, Symbol, default: :all_clients
    attribute :no_service_after_date, Date, lazy: true, default: -> (r,_) { r.default_no_service_after_date }
    attribute :no_recent_service_project_ids, Array, default: []

    validates_presence_of :start, :end, :sub_population

    def default_no_service_after_date
      Date.today - 90.day
    end

  end
end
