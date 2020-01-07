###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module CohortColumns
  class Reported < CohortBoolean
    attribute :column, Boolean, lazy: true, default: :reported
    attribute :translation_key, String, lazy: true, default: 'Reported'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }
  end
end
