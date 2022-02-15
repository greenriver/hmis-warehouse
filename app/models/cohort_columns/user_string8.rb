###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class UserString8 < CohortString
    attribute :column, String, lazy: true, default: :user_string_8
    attribute :translation_key, String, lazy: true, default: 'User String 8'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }
  end
end
