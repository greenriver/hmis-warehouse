module ClaimsReporting
  class MedicalClaim < HealthBase
    belongs_to :patient, class_name: 'Health::Patient', primary_key: :medicaid_id, foreign_key: :medicaid_id
  end
end
