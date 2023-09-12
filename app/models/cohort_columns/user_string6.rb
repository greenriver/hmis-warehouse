###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class UserString6 < CohortString
    attribute :column, String, lazy: true, default: :user_string_6
    attribute :translation_key, String, lazy: true, default: 'User String 6'
    attribute :title, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.translation_key) }
  end
end
