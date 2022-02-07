###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class HousingOpportunity < Select
    attribute :column, String, lazy: true, default: :housing_opportunity
    attribute :translation_key, String, lazy: true, default: 'Housing Opportunity'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }
  end
end
