###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class PreviousRemovalReason < ReadOnly
    attribute :column, String, lazy: true, default: :previous_removal_reason
    attribute :translation_key, String, lazy: true, default: 'Previous Removal Reason'
    attribute :title, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.translation_key) }
    attribute :description_translation_key, String, lazy: true, default: ->(model, _attr) { "#{model.translation_key} Description" }
    attribute :description, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.description_translation_key) }

    def available_for_rules?
      false
    end

    def value(cohort_client) # OK
      change = cohort_client.cohort_client_changes.sort_by(&:changed_at).
        detect do |c|
          c.change.in?(['destroy', 'deactivate'])
        end
      return unless change

      "#{change.reason} on #{change.changed_at.to_date}"
    end
  end
end
