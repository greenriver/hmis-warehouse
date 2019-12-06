###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module CohortColumns
  class HousedDate < CohortDate
    attribute :column, String, lazy: true, default: :housed_date
    attribute :translation_key, String, lazy: true, default: 'Housed Date'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }
  end
end
