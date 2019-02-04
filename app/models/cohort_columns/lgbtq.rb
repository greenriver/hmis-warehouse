module CohortColumns
  class Lgbtq < Select
    attribute :column, String, lazy: true, default: :lgbtq
    attribute :translation_key, String, lazy: true, default: 'LGBTQ'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}
  end
end
