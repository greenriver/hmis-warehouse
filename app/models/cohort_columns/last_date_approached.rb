###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class LastDateApproached < CohortDate
    attribute :column, String, lazy: true, default: :last_date_approached
    attribute :translation_key, String, lazy: true, default: 'Last Date Approached'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }
  end
end
