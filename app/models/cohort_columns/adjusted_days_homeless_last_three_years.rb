###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class AdjustedDaysHomelessLastThreeYears < ::CohortColumns::Integer
    attribute :column, String, lazy: true, default: :adjusted_days_homeless_last_three_years
    attribute :translation_key, String, lazy: true, default: 'Static Days Homeless Last 3 Years'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }

    def default_value?
      true
    end

    def description
      'Days homeless in past 3 years for the client as calculated when added to the cohort (ES, SH, SO, or TH  with no overlapping TH or PH)'
    end

    def default_value(client_id)
      effective_date = cohort.effective_date || Date.current
      # Use the pre-calculated value if we're looking at today
      if effective_date == Date.current
        GrdaWarehouse::WarehouseClientsProcessed.service_history.find_by(client_id: client_id)&.days_homeless_last_three_years || GrdaWarehouse::Hud::Client.days_homeless_in_last_three_years(client_id: client_id, on_date: effective_date)
      else
        GrdaWarehouse::Hud::Client.days_homeless_in_last_three_years(client_id: client_id, on_date: effective_date)
      end
    end
  end
end
