###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class MostRecentClsSheltered < ReadOnly
    attribute :column, String, lazy: true, default: :most_recent_cls_sheltered
    attribute :translation_key, String, lazy: true, default: 'Most Recent Current Living Situation Sheltered?'
    attribute :title, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.translation_key) }
    attribute :description_translation_key, String, lazy: true, default: 'Most-recent Current Living Situation for the client was not "Place not meant for habitation (e.g., a vehicle, an abandoned building, bus/train/subway station/airport or anywhere outside)" or unknown.'
    attribute :description, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.description_translation_key) }

    def available_for_rules?
      false
    end

    def value(cohort_client) # OK
      checkmark_or_x text_value(cohort_client)
    end

    def text_value(cohort_client)
      # NOTE: while this relies exclusively on the Boston calculator, the calculator simply looks for CLS
      GrdaWarehouse::CasProjectClientCalculator::Boston.new.majority_sheltered(cohort_client.client) || false
    end
  end
end
