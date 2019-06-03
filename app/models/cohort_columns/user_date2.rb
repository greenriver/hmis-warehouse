###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module CohortColumns
  class UserDate2 < CohortDate
    attribute :column, String, lazy: true, default: :user_date_2
    attribute :translation_key, String, lazy: true, default: 'User Date 2'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}
  end
end
