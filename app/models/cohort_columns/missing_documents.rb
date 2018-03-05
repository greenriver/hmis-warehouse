module CohortColumns
  class MissingDocuments < ReadOnly
    attribute :column, String, lazy: true, default: :missing_documents
    attribute :title, String, lazy: true, default: 'Missing Documents'



    def value(cohort_client)
      required_documents = GrdaWarehouse::AvailableFileTag.document_ready
      cohort_client.client.document_readiness(required_documents).select{|m| m.available == false}.map(&:name).join('; ')
    end
  end
end
