###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# FIXME: we should remove this column
module CohortColumns
  class Ethnicity < ReadOnly
    attribute :column, String, lazy: true, default: :ethnicity
    attribute :translation_key, String, lazy: true, default: 'Ethnicity'
    attribute :title, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.translation_key) }
    attribute :description_translation_key, String, lazy: true, default: 'Deprecated per FY2024 HMIS specification, ethnicity of a client.'
    attribute :description, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.description_translation_key) }

    def available_for_rules?
      false
    end

    def value(cohort_client)
      ethnicities = cohort_client.client.source_clients.map(&:Ethnicity)&.select { |v| v.in?([0, 1]) }&.map do |v|
        ::HudUtility.ethnicity(v)
      end
      ethnicities.uniq&.sort
    end

    def display_read_only(_user)
      ethnicities = value(cohort_client)
      return '' unless ethnicities

      ethnicities.join('; ')
    end
  end
end
