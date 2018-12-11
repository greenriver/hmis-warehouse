# ### HIPPA Risk Assessment
# Risk: Indirectly relates to a patient. Binary data may contain PHI
# Control: PHI attributes documented in base class
module Health
  class SignableDocumentFile < Health::HealthFile

    belongs_to :signable_document, class_name: 'Health::SignableDocument', foreign_key: :parent_id

    def title
      'Signable Care Plan'
    end
  end
end