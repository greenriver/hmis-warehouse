###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class UserDate24 < CohortDate
    attribute :column, String, lazy: true, default: :user_date_24
    attribute :translation_key, String, lazy: true, default: 'User Date 24'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }
  end
end
