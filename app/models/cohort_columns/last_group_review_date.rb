module CohortColumns
  class LastGroupReviewDate < CohortDate
    attribute :column, String, lazy: true, default: :last_group_review_date
    attribute :translation_key, String, lazy: true, default: 'Last Group Review Date'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}
  end
end
