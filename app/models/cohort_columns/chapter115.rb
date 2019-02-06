module CohortColumns
  class Chapter115 < Select
    attribute :column, String, lazy: true, default: :chapter_115
    attribute :translation_key, String, lazy: true, default: 'Chapter 115'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}

  end
end
