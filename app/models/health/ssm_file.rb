module Health
  class SsmFile < Health::HealthFile

    belongs_to :ssm, class_name: 'Health::SelfSufficiencyMatrixForm', foreign_key: :parent_id

  end
end