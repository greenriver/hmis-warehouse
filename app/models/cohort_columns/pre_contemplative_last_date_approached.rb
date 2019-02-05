module CohortColumns
  class PreContemplativeLastDateApproached < CohortDate
    attribute :column, String, lazy: true, default: :pre_contemplative_last_date_approached
    attribute :translation_key, String, lazy: true, default: 'Pre-contemplative Last Date Approached'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}
  end
end
