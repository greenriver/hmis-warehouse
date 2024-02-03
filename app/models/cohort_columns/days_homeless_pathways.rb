###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class DaysHomelessPathways < ReadOnly
    attribute :column, String, lazy: true, default: :days_homeless_pathways
    attribute :translation_key, String, lazy: true, default: 'Days Homeless For Pathways'
    attribute :title, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.translation_key) }
    attribute :description_translation_key, String, lazy: true, default: 'Days homeless as calculated for the Pathways assessment. This includes both HMIS and self-reported days.'
    attribute :description, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.description_translation_key) }

    def available_for_rules?
      false
    end

    def value(cohort_client) # OK
      client = cohort_client.client
      # NOTE: this will return nothing unless the client has a recent pathways or transfer assessment
      return unless client&.source_clients&.map(&:most_recent_pathways_or_rrh_assessment)&.any?

      GrdaWarehouse::CasProjectClientCalculator::Boston.new.days_homeless_in_last_three_years_cached(client)
    end
  end
end
