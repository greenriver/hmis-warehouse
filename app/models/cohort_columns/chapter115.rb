###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class Chapter115 < Select
    attribute :column, String, lazy: true, default: :chapter_115
    attribute :translation_key, String, lazy: true, default: 'Chapter 115'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }
  end
end
