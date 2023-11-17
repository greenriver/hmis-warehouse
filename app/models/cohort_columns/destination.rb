###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class Destination < Select
    attribute :column, String, lazy: true, default: :destination
    attribute :translation_key, String, lazy: true, default: 'Destination (Program Type)'
    attribute :title, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.translation_key) }
    attribute :hint, String, lazy: true, default: 'Do not complete until housed.'
    attribute :description_translation_key, String, lazy: true, default: 'Manually entered destination'
    attribute :description, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.description_translation_key) }
  end
end
