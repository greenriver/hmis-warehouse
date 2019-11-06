###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module CohortColumns
  class UserNumeric8 < ::CohortColumns::Integer
    attribute :column, String, lazy: true, default: :user_numeric_8
    attribute :translation_key, String, lazy: true, default: 'User Numeric 9'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}
  end
end
