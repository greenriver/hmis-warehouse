module CohortColumns
  class LastDateApproached < CohortDate
    attribute :column, String, lazy: true, default: :last_date_approached
    attribute :translation_key, String, lazy: true, default: 'Last Date Approached'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}
  end
end
