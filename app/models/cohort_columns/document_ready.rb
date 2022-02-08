###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class DocumentReady < Select
    attribute :column, String, lazy: true, default: :document_ready
    attribute :translation_key, String, lazy: true, default: 'Document Ready'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }
  end
end
