module CohortColumns
  class VispdatScore < ReadOnly
    attribute :column, String, lazy: true, default: :vispdat_score
    attribute :title, String, lazy: true, default: 'VI-SPDAT Score'

    def value(cohort_client) # TODO: N=1 move_to_processed
      cohort_client.client.processed_service_history&.vispdat_score
    end
  end
end
