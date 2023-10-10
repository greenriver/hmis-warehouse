###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class UserBoolean12 < CohortBoolean
    attribute :column, Boolean, lazy: true, default: :user_boolean_12
    attribute :translation_key, String, lazy: true, default: 'User Boolean 12'
    attribute :title, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.translation_key) }
  end
end
