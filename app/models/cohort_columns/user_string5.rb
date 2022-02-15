###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class UserString5 < CohortString
    attribute :column, String, lazy: true, default: :user_string_5
    attribute :translation_key, String, lazy: true, default: 'User String 5'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }
  end
end
