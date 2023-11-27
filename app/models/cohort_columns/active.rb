###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class Active < CohortBoolean
    attribute :column, Boolean, lazy: true, default: :active
    attribute :translation_key, String, lazy: true, default: 'Active'
    attribute :title, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.translation_key) }
    attribute :description_translation_key, String, lazy: true, default: ->(model, _attr) { "#{model.translation_key} Description" }
    attribute :description, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.description_translation_key) }

    def display_as_editable?(user, _cohort_client, on_cohort: cohort) # rubocop:disable Lint/UnusedMethodArgument
      user.can_manage_inactive_cohort_clients?
    end

    def default_value?
      true
    end

    def default_value(_client_id)
      true
    end
  end
end
