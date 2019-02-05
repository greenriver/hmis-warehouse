module CohortColumns
  class Status < Select
    attribute :column, String, lazy: true, default: :status
    attribute :translation_key, String, lazy: true, default: 'Risk'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}

    def description
      'Risk of becoming chronic'
    end

  end
end
