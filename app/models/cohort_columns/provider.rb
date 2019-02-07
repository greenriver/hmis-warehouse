module CohortColumns
  class Provider < CohortString
    attribute :column, String, lazy: true, default: :provider
    attribute :translation_key, String, lazy: true, default: 'Provider'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}
  end
end
