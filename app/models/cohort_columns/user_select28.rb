###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class UserSelect28 < Select
    attribute :column, String, lazy: true, default: :user_select_28
    attribute :translation_key, String, lazy: true, default: 'User Select 28'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }
  end
end
