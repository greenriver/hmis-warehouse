module CohortColumns
  class Rank < ::CohortColumns::Integer
    attribute :column, String, lazy: true, default: :rank
    attribute :translation_key, String, lazy: true, default: 'Rank'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}
  end
end
