module CohortColumns
  class MinimumBedroomSize < ::CohortColumns::Integer
    attribute :column, String, lazy: true, default: :minimum_bedroom_size
    attribute :translation_key, String, lazy: true, default: 'Minimum Bedroom Size'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}
  end
end
