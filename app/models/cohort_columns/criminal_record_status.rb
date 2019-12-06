###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module CohortColumns
  class CriminalRecordStatus < Select
    attribute :column, String, lazy: true, default: :criminal_record_status
    attribute :translation_key, String, lazy: true, default: 'Criminal Record Status'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }
  end
end
