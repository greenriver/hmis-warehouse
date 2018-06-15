module CohortColumns
  class MissingDocuments < ReadOnly
    attribute :column, String, lazy: true, default: :missing_documents
    attribute :title, String, lazy: true, default: 'Missing Documents'

    def value(cohort_client) # OK
      cohort_client.client.processed_service_history&.missing_documents
    end
  end
end
