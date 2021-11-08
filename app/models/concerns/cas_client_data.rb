###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CasClientData
  extend ActiveSupport::Concern
  included do
    private def days_homeless_in_last_three_years_cached
      processed_service_history&.days_homeless_last_three_years
    end

    private def literally_homeless_last_three_years_cached
      processed_service_history&.literally_homeless_last_three_years
    end

    private def days_homeless_for_vispdat_prioritization
      vispdat_prioritization_days_homeless || days_homeless_in_last_three_years
    end
  end
end
