###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module CohortColumns
  class LgbtqFromHmis < ReadOnly
    attribute :column, String, lazy: true, default: :lgbtq_from_hmis
    attribute :translation_key, String, lazy: true, default: 'Sexual Orientation (from HMIS)'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}
  end
end