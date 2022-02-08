###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class MinimumBedroomSize < ::CohortColumns::Integer
    attribute :column, String, lazy: true, default: :minimum_bedroom_size
    attribute :translation_key, String, lazy: true, default: 'Minimum Bedroom Size'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }
  end
end
