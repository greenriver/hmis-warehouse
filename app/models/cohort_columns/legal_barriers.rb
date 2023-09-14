###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class LegalBarriers < Select
    attribute :column, String, lazy: true, default: :legal_barriers
    attribute :translation_key, String, lazy: true, default: 'Legal Barriers'
    attribute :title, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.translation_key) }

    def available_for_rules?
      false
    end
  end
end
