module CohortColumns
  class VispdatScore < ReadOnly
    attribute :column, String, lazy: true, default: :vispdat_score
    attribute :translation_key, String, lazy: true, default: 'VI-SPDAT Score'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}

    def value(cohort_client) # OK
      cohort_client.client.processed_service_history&.vispdat_score
    end
  end
end
