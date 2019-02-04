module CohortColumns
  class SleepingLocation < Select
    attribute :column, String, lazy: true, default: :sleeping_location
    attribute :translation_key, String, lazy: true, default: 'Sleeping Location'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}

    def description
      'Manually entered'
    end

  end
end
