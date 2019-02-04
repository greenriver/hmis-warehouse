module CohortColumns
  class Destination < Select
    attribute :column, String, lazy: true, default: :destination
    attribute :translation_key, String, lazy: true, default: 'Destination (Program Type)'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}
    attribute :hint, String, lazy: true, default: 'Do not complete until housed.'

    def description
      'Manually entered destination'
    end

  end
end
