module CohortColumns
  class VispdatPriorityScore < ReadOnly
    attribute :column, String, lazy: true, default: :vispdat_priority_score
    attribute :translation_key, String, lazy: true, default: 'VI-SPDAT Priority Score'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}

    def value(cohort_client) # OK
      cohort_client.client.processed_service_history&.vispdat_priority_score
    end
  end
end
