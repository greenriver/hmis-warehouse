module CohortColumns
  class DocumentReady < Base
    attribute :column, String, lazy: true, default: :document_ready
    attribute :title, String, lazy: true, default: 'Document Ready'

    def default_input_type
      :select
    end

    def available_options
      ['Precontemplative', 'HAN Obtained', 'Limited CAS Signed', 'Disability Verification Obtained']
    end
  end
end
