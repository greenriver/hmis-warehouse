###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class VaEligible < Select
    attribute :column, String, lazy: true, default: :va_eligible
    attribute :translation_key, String, lazy: true, default: 'VA Eligible'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }
  end
end
