###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module CohortColumns
  class Ethnicity < ReadOnly
    attribute :column, String, lazy: true, default: :ethnicity
    attribute :translation_key, String, lazy: true, default: 'Ethnicity'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}

    def value(cohort_client)
      cohort_client.client.source_clients.map(&:Ethnicity)&.select{|v| v.in?([0,1])}&.map do |v|
        ::HUD.ethnicity(v)
      end.uniq&.sort
    end

    def display_read_only user
      if ethnicities = value(cohort_client)
        ethnicities.join('; ')
      end
    end

  end
end
