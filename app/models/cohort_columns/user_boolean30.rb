###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class UserBoolean30 < CohortBoolean
    attribute :column, Boolean, lazy: true, default: :user_boolean_30
    attribute :translation_key, String, lazy: true, default: 'User Boolean 30'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }
  end
end
