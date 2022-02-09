###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class UserNumeric5 < ::CohortColumns::Integer
    attribute :column, String, lazy: true, default: :user_numeric_5
    attribute :translation_key, String, lazy: true, default: 'User Numeric 5'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }
  end
end
