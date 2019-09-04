###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module CohortColumns
  class DaysOnCohort < ReadOnly
    attribute :column, String, lazy: true, default: :days_on_cohort
    attribute :translation_key, String, lazy: true, default: 'Days on Cohort'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}


    def value(cohort_client)
      (Date.current - cohort_client.created_at.to_date).to_i
    end
  end
end