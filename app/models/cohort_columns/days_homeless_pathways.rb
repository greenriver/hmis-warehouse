###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class DaysHomelessPathways < ReadOnly
    attribute :column, String, lazy: true, default: :days_homeless_pathways
    attribute :translation_key, String, lazy: true, default: 'Days Homeless For Pathways'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }

    def value(cohort_client) # OK
      # NOTE: while this relies exclusively on the Boston calculator, the calculator will return client.processed_service_history&.days_homeless_last_three_years
      # if no pathways assessment has been completed
      GrdaWarehouse::CasProjectClientCalculator::Boston.new.days_homeless_in_last_three_years_cached(cohort_client.client)
    end
  end
end
