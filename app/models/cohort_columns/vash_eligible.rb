###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class VashEligible < CohortBoolean
    attribute :column, Boolean, lazy: true, default: :vash_eligible
    attribute :translation_key, String, lazy: true, default: 'VASH Eligible'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }
  end
end
