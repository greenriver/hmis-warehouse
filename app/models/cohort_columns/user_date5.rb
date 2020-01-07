###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module CohortColumns
  class UserDate5 < CohortDate
    attribute :column, String, lazy: true, default: :user_date_5
    attribute :translation_key, String, lazy: true, default: 'User Date 5'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }
  end
end
