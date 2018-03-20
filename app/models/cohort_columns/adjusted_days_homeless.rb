module CohortColumns
  class AdjustedDaysHomeless < ::CohortColumns::Integer
    attribute :column, String, lazy: true, default: :adjusted_days_homeless
    attribute :title, String, lazy: true, default: 'Static Days Homeless'

    def has_default_value?
      true
    end

    def description
      'Days homeless for the client as calculated when added to the cohort'
    end

    def default_value client_id
      effective_date = cohort.effective_date || Date.today
      GrdaWarehouse::Hud::Client.days_homeless(client_id: client_id, on_date: effective_date)
    end

  end
end
