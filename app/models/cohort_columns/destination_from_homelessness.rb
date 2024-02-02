###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class DestinationFromHomelessness < ReadOnly
    include ArelHelper
    attribute :column, String, lazy: true, default: :destination_from_homelessness
    attribute :translation_key, String, lazy: true, default: 'Recent Exits from Homelessness'
    attribute :title, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.translation_key) }
    attribute :description_translation_key, String, lazy: true, default: 'Dates for any exits to permanent destinations from homeless projects for the client that occurred in the last 90 days.'
    attribute :description, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.description_translation_key) }

    def value(cohort_client) # OK
      # This will return a hidden span with the most recent date for sorting as part of the display value
      cohort_client.destination_from_homelessness
    end
  end
end
