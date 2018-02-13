module CohortColumns
  class MissingDocuments < Base
    attribute :column, String, lazy: true, default: :missing_documents
    attribute :title, String, lazy: true, default: 'Missing Documents'

    def default_input_type
      :read_only
    end

    def value(cohort_client)
      required_documents = GrdaWarehouse::Config.get(:document_ready)
      cohort_client.client.document_readiness(required_documents).select{|m| m.available == false}.map(&:name).join('; ')
    end
  end
end
