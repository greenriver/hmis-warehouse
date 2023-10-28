###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class UserDate13 < CohortDate
    attribute :column, String, lazy: true, default: :user_date_13
    attribute :translation_key, String, lazy: true, default: 'User Date 13'
    attribute :title, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.translation_key) }
  end
end
