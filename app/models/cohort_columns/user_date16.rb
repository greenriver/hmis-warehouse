###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class UserDate16 < CohortDate
    attribute :column, String, lazy: true, default: :user_date_16
    attribute :translation_key, String, lazy: true, default: 'User Date 16'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }
  end
end
