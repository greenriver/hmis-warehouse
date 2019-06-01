###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module CohortColumns
  class UserSelect3 < Select
    attribute :column, String, lazy: true, default: :user_select_3
    attribute :translation_key, String, lazy: true, default: 'User Select 3'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}
  end
end
