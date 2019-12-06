###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module CohortColumns
  class UserDate1 < CohortDate
    attribute :column, String, lazy: true, default: :user_date_1
    attribute :translation_key, String, lazy: true, default: 'User Date 1'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }
  end
end
