###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class AdjustedDaysLiterallyHomelessLastThreeYears < ::CohortColumns::Integer
    attribute :column, String, lazy: true, default: :adjusted_days_literally_homeless_last_three_years
    attribute :translation_key, String, lazy: true, default: 'Static Days Literally Homeless Last 3 Years'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }

    def default_value?
      true
    end

    def description
      'Days Literally homeless in past 3 years for the client as calculated when added to the cohort (ES, SH, or SO with no overlapping TH or PH)'
    end

    def default_value(client_id)
      effective_date = cohort.effective_date || Date.current
      GrdaWarehouse::Hud::Client.literally_homeless_last_three_years(client_id: client_id, on_date: effective_date)
    end
  end
end
