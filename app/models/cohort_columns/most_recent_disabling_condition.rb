###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module CohortColumns
  class MostRecentDisablingCondition < ReadOnly
    attribute :column, String, lazy: true, default: :most_recent_disabling_condition
    attribute :translation_key, String, lazy: true, default: 'Most-Recent Disabling Condition'
    attribute :title, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.translation_key) }
    attribute :description_translation_key, String, lazy: true, default: 'The most-recent Disabling Condition based on EntryDate and DateUpdated.  If this cohort uses automation, the situation will be limited to projects in the selected project group.'
    attribute :description, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.description_translation_key) }

    def available_for_rules?
      false
    end
  end
end
