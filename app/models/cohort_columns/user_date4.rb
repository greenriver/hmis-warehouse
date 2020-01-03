###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module CohortColumns
  class UserDate4 < CohortDate
    attribute :column, String, lazy: true, default: :user_date_4
    attribute :translation_key, String, lazy: true, default: 'User Date 4'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }
  end
end
