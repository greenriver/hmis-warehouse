###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class SourceClientPersonalIds < ReadOnly
    attribute :column, String, lazy: true, default: :source_client_personal_ids
    attribute :translation_key, String, lazy: true, default: 'Personal IDs'
    attribute :title, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.translation_key) }
    attribute :description_translation_key, String, lazy: true, default: 'Personal IDs this client has in HMIS source data'
    attribute :description, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.description_translation_key) }

    def available_for_rules?
      false
    end

    def value(cohort_client) # OK
      cohort_client.client.source_clients.map(&:personal_id).compact.uniq.join(', ')
    end
  end
end
