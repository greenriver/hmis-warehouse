###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class UserDate26 < CohortDate
    attribute :column, String, lazy: true, default: :user_date_26
    attribute :translation_key, String, lazy: true, default: 'User Date 26'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }
  end
end
