###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class DaysHomelessPathways < ReadOnly
    attribute :column, String, lazy: true, default: :days_homeless_pathways
    attribute :translation_key, String, lazy: true, default: 'Days Homeless For Pathways'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }

    def value(cohort_client) # OK
      client = cohort_client.client
      # NOTE: this will return nothing unless the client has a recent pathways or transfer assessment
      return unless client&.source_clients&.map(&:most_recent_pathways_or_rrh_assessment)&.any?

      GrdaWarehouse::CasProjectClientCalculator::Boston.new.days_homeless_in_last_three_years_cached(client)
    end
  end
end
