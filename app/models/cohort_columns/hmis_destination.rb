module CohortColumns
  class HmisDestination < ReadOnly
    attribute :column, String, lazy: true, default: :hmis_destination
    attribute :translation_key, String, lazy: true, default: 'Exit Destination (HMIS)'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}

    def value cohort_client
      cohort_client.client.processed_service_history&.last_exit_destination
    end

  end
end
