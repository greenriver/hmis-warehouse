###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class SpecialNeeds < CohortString
    attribute :column, String, lazy: true, default: :special_needs
    attribute :translation_key, String, lazy: true, default: 'Special Needs'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }
  end
end
