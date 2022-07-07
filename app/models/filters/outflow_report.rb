###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# provides validation for date ranges
module Filters
  class OutflowReport < FilterBase
    attribute :no_service_after_date, Date, lazy: true, default: ->(r, _) { r.default_no_service_after_date }
    attribute :no_recent_service_project_ids, Array, default: []
    attribute :limit_to_vispdats, Boolean, default: false
    attribute :require_homeless_enrollment, Boolean, default: false

    validates_presence_of :start, :end, :sub_population

    def default_no_service_after_date
      Date.current - 90.day
    end

    def update(filters)
      super
      self.no_service_after_date = filters.dig(:no_service_after_date)&.to_date
      self.no_recent_service_project_ids = filters.dig(:no_recent_service_project_ids)&.reject(&:blank?)&.map(&:to_i).presence
      self.limit_to_vispdats = filters.dig(:limit_to_vispdats).in?(['1', 'true', true]) unless filters.dig(:limit_to_vispdats).nil?
      self.require_homeless_enrollment = filters.dig(:require_homeless_enrollment).in?(['1', 'true', true]) unless filters.dig(:require_homeless_enrollment).nil?
      self
    end
    alias set_from_params update

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
