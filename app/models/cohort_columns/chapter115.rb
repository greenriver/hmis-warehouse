module CohortColumns
  class Chapter115 < Select
    attribute :column, String, lazy: true, default: :chapter_115
    attribute :title, String, lazy: true, default: _('Chapter 115')


  end
end
