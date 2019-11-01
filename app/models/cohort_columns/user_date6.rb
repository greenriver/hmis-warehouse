###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module CohortColumns
  class UserDate6 < CohortDate
    attribute :column, String, lazy: true, default: :user_date_6
    attribute :translation_key, String, lazy: true, default: 'User Date 6'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}
  end
end
