# ### HIPPA Risk Assessment
# Risk: Indirectly relates to a patient. Binary data may contain PHI
# Control: PHI attributes documented in base class
module Health
  class SsmFile < Health::HealthFile

    belongs_to :ssm, class_name: 'Health::SelfSufficiencyMatrixForm', foreign_key: :parent_id

  end
end