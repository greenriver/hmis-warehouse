module CohortColumns
  class HousedDate < CohortDate
    attribute :column, String, lazy: true, default: :housed_date
    attribute :translation_key, String, lazy: true, default: 'Housed Date'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}
  end
end
