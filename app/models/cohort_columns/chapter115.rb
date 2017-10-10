module CohortColumns
  class Chapter115 < Base
    attribute :column, String, lazy: true, default: :chapter_115
    attribute :title, String, lazy: true, default: 'Chapter 115'
  end
end