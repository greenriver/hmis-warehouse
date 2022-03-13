###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class AdjustedDaysHomeless < ::CohortColumns::Integer
    attribute :column, String, lazy: true, default: :adjusted_days_homeless
    attribute :translation_key, String, lazy: true, default: 'Static Days Homeless'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }

    def default_value?
      true
    end

    def description
      'Days homeless for the client as calculated when added to the cohort'
    end

    def default_value(client_id)
      effective_date = cohort.effective_date || Date.current
      # Use the pre-calculated value if we're looking at today
      if effective_date == Date.current
        GrdaWarehouse::WarehouseClientsProcessed.service_history.find_by(client_id: client_id)&.homeless_days
      else
        GrdaWarehouse::Hud::Client.days_homeless(client_id: client_id, on_date: effective_date)
      end
    end
  end
end
