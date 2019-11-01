###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module CohortColumns
  class UserNumeric6 < ::CohortColumns::Integer
    attribute :column, String, lazy: true, default: :user_numeric_6
    attribute :translation_key, String, lazy: true, default: 'User Numeric 6'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}
  end
end
