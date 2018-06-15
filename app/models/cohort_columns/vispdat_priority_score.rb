module CohortColumns
  class VispdatPriorityScore < ReadOnly
    attribute :column, String, lazy: true, default: :vispdat_priority_score
    attribute :title, String, lazy: true, default: 'VI-SPDAT Priority Score'


    def value(cohort_client) # OK
      cohort_client.client.processed_service_history&.vispdat_priority_score
    end
  end
end
