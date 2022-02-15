###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class Veteran < CohortBoolean
    attribute :column, String, lazy: true, default: :veteran
    attribute :translation_key, String, lazy: true, default: 'Veteran'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }

    def value(cohort_client) # OK
      cohort_client.client.veteran?
    end
  end
end
