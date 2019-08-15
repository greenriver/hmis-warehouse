###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module CohortColumns
  class UserBoolean9 < CohortBoolean
    attribute :column, Boolean, lazy: true, default: :user_boolean_9
    attribute :translation_key, String, lazy: true, default: 'User Boolean 9'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}
  end
end
