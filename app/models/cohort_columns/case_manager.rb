###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class CaseManager < CohortString
    attribute :column, String, lazy: true, default: :case_manager
    attribute :translation_key, String, lazy: true, default: 'Case Manager'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }

    def description
      'Manually entered'
    end
  end
end
