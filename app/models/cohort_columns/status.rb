###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class Status < Select
    attribute :column, String, lazy: true, default: :status
    attribute :translation_key, String, lazy: true, default: 'Risk'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }

    def description
      'Risk of becoming chronic'
    end
  end
end
