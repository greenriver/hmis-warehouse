###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# provides validation for date ranges
module Filters
  class OutflowReport < FilterBase
    attribute :sub_population, Symbol, default: :clients
    attribute :no_service_after_date, Date, lazy: true, default: ->(r, _) { r.default_no_service_after_date }
    attribute :no_recent_service_project_ids, Array, default: []
    attribute :limit_to_vispdats, Boolean, default: false
    attribute :races, Array, default: []
    attribute :ethnicities, Array, default: []
    attribute :genders, Array, default: []
    attribute :require_homeless_enrollment, Boolean, default: false

    validates_presence_of :start, :end, :sub_population

    def default_no_service_after_date
      Date.current - 90.day
    end

    # These are not presented in the UI, but need to be set to nothing or all homeless projects are returned
    def default_project_type_codes
      []
    end

    def available_sub_populations
      @available_sub_populations = GrdaWarehouse::WarehouseReports::Dashboard::Base.available_sub_populations.dup
      @available_sub_populations['Youth at Search Start'] = :youth_at_search_start
      @available_sub_populations['Youth at Housed Date'] = :youth_at_housed_date
      @available_sub_populations
    end
  end
end
