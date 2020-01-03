###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module CohortColumns
  class UserSelect8 < Select
    attribute :column, String, lazy: true, default: :user_select_8
    attribute :translation_key, String, lazy: true, default: 'User Select 8'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }
  end
end
