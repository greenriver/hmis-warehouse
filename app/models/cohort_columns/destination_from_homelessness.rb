###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class DestinationFromHomelessness < ReadOnly
    include ArelHelper
    attribute :column, String, lazy: true, default: :destination_from_homelessness
    attribute :translation_key, String, lazy: true, default: 'Recent Exits from Homelessness'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }

    def value(cohort_client) # OK
      # FIXME: this should have a hidden span with the most recent date, if that's possible
      cohort_client.destination_from_homelessness
    end
  end
end
