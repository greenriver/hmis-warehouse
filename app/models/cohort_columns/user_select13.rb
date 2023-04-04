###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class UserSelect13 < Select
    attribute :column, String, lazy: true, default: :user_select_13
    attribute :translation_key, String, lazy: true, default: 'User Select 13'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }
  end
end
