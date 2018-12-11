# ### HIPPA Risk Assessment
# Risk: Indirectly relates to a patient. Binary data may contain PHI
# Control: PHI attributes documented in base class
module Health
  class CareplanFile < Health::HealthFile

    belongs_to :careplan, class_name: 'Health::Careplan', foreign_key: :parent_id

    def title
      "Careplan"
    end

  end
end