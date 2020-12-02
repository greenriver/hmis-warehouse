module ClaimsReporting
  class MedicalClaim < HealthBase
    belongs_to :patient,
               class_name: 'Health::Patient',
               primary_key: :medicaid_id,
               foreign_key: :medicaid_id

    def modifiers
      [
        procedure_modifier_1,
        procedure_modifier_2,
        procedure_modifier_3,
        procedure_modifier_4,
      ].select(&:present?)
    end

    def procedure_with_modifiers
      # sort is here since this is used as a key to match against other data
      ([procedure_code] + modifiers.sort).join('>').to_s
    end
  end
end
