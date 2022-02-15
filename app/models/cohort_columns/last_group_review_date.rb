###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class LastGroupReviewDate < CohortDate
    attribute :column, String, lazy: true, default: :last_group_review_date
    attribute :translation_key, String, lazy: true, default: 'Last Group Review Date'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }
  end
end
