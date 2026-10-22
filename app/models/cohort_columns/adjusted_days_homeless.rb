###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module CohortColumns
  class AdjustedDaysHomeless < ::CohortColumns::Integer
    attribute :column, String, lazy: true, default: :adjusted_days_homeless
    attribute :translation_key, String, lazy: true, default: 'Static Days Homeless'
    attribute :title, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.translation_key) }
    attribute :description_translation_key, String, lazy: true, default: 'Days homeless for the client as calculated when added to the cohort'
    attribute :description, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.description_translation_key) }

    def default_value?
      true
    end

    def default_value(client_id)
      cohort.length_of_time_stats([client_id]).homeless_counts[client_id] || 0
    end
  end
end
