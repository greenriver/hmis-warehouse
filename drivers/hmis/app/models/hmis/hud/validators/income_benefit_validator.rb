class Hmis::Hud::Validators::IncomeBenefitValidator < Hmis::Hud::Validators::BaseValidator
  IGNORED = [
    :ExportID,
    :DateCreated,
    :DateUpdated,
  ].freeze

  def configuration
    Hmis::Hud::IncomeBenefit.hmis_configuration(version: '2022').except(*IGNORED)
  end

  INCOME_SOURCES_UNSPECIFIED = 'At least one income source must be selected.'.freeze
  BENEFIT_SOURCES_UNSPECIFIED = 'At least one benefit must be selected.'.freeze
  INSURANCE_SOURCES_UNSPECIFIED = 'At least one insurance provider must be selected.'.freeze

  def self.dependent_items
    {
      income_from_any_source: [
        :earned,
        :unemployment,
        :ssi,
        :ssdi,
        :va_disability_service,
        :va_disability_non_service,
        :private_disability,
        :workers_comp,
        :tanf,
        :ga,
        :soc_sec_retirement,
        :pension,
        :child_support,
        :alimony,
        :other_income_source,
      ],
      benefits_from_any_source: [
        :snap,
        :wic,
        :tanf_child_care,
        :tanf_transportation,
        :other_tanf,
        :other_benefits_source,
      ],
      insurance_from_any_source: [
        :medicaid,
        :medicare,
        :schip,
        :va_medical_services,
        :employer_provided,
        :cobra,
        :private_pay,
        :state_health_ins,
        :indian_health_services,
        :other_insurance,
      ],
    }
  end

  def validate(record)
    super(record) do
      # Error if income is Yes but no sources are Yes
      record.errors.add :income_from_any_source, :invalid, full_message: INCOME_SOURCES_UNSPECIFIED if record.income_from_any_source == 1 && self.class.dependent_items[:income_from_any_source].none? { |f| record.send(f) == 1 }

      # Error if benefits is Yes but no sources are Yes
      record.errors.add :benefits_from_any_source, :invalid, full_message: BENEFIT_SOURCES_UNSPECIFIED if record.benefits_from_any_source == 1 && self.class.dependent_items[:benefits_from_any_source].none? { |f| record.send(f) == 1 }

      # Error if insurance is Yes but no sources are Yes
      record.errors.add :insurance_from_any_source, :invalid, full_message: INSURANCE_SOURCES_UNSPECIFIED if record.insurance_from_any_source == 1 && self.class.dependent_items[:insurance_from_any_source].none? { |f| record.send(f) == 1 }
    end
  end
end
