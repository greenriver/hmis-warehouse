module CohortColumns
  class MissingDocuments < ReadOnly
    attribute :column, String, lazy: true, default: :missing_documents
    attribute :title, String, lazy: true, default: 'Missing Documents'

    def value(cohort_client) # OK
      cohort_client.missing_documents
    end
  end
end
