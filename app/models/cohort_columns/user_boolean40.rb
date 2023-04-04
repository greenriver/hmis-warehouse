###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class UserBoolean40 < CohortBoolean
    attribute :column, Boolean, lazy: true, default: :user_boolean_40
    attribute :translation_key, String, lazy: true, default: 'User Boolean 40'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }
  end
end
