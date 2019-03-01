module CohortColumns
  class ExitDestination < Select
    attribute :column, String, lazy: true, default: :exit_destination
    attribute :translation_key, String, lazy: true, default: 'Exit Destination'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}

    def description
      'Manually entered destination'
    end

  end
end
