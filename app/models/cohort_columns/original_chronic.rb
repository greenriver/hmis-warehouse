###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class OriginalChronic < CohortBoolean
    attribute :column, Boolean, lazy: true, default: :original_chronic
    attribute :translation_key, String, lazy: true, default: 'On Original Chronic List'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }

    def description
      'Manually entered record of original chronic membership'
    end
  end
end
