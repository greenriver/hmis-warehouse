###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module CohortColumns
  class NotAVet < Select
    attribute :column, String, lazy: true, default: :not_a_vet
    attribute :translation_key, String, lazy: true, default: 'Not a Vet'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}
  end
end
