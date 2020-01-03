###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module CohortColumns
  class UserNumeric10 < ::CohortColumns::Integer
    attribute :column, String, lazy: true, default: :user_numeric_10
    attribute :translation_key, String, lazy: true, default: 'User Numeric 10'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }
  end
end
