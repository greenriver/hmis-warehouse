###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class Ethnicity < ReadOnly
    attribute :column, String, lazy: true, default: :ethnicity
    attribute :translation_key, String, lazy: true, default: 'Ethnicity'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }

    def value(cohort_client)
      ethnicities = cohort_client.client.source_clients.map(&:Ethnicity)&.select { |v| v.in?([0, 1]) }&.map do |v|
        ::HUD.ethnicity(v)
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
