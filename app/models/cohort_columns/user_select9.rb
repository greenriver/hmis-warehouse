###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module CohortColumns
  class UserSelect9 < Select
    attribute :column, String, lazy: true, default: :user_select_9
    attribute :translation_key, String, lazy: true, default: 'User Select 9'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }
  end
end
