###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Hmis::Hud::Validators::IncomeBenefitValidator < Hmis::Hud::Validators::BaseValidator
  IGNORED = [
    :ExportID,
    :DateCreated,
    :DateUpdated,
    :NoVHAReason, # skip for now since its not added yet
  ].freeze

  def configuration
    Hmis::Hud::IncomeBenefit.hmis_configuration(version: '2024').except(*IGNORED)
  end

  INCOME_SOURCES_UNSPECIFIED = 'At least one income source must be selected.'
  BENEFIT_SOURCES_UNSPECIFIED = 'At least one benefit must be selected.'
  INSURANCE_SOURCES_UNSPECIFIED = 'At least one insurance provider must be selected.'
  INCOME_SOURE_WITHOUT_SUMMARY = 'All income sources must be blank or zero unless Income from Any Source is Yes.'
  BENEFIT_SOURCE_WITHOUT_SUMMARY = 'All benefits must be unchecked unless Non-Cash Benefits from Any Source is Yes.'
  INSURANCE_SOURCE_WITHOUT_SUMMARY = 'All insurance providers must be unchecked unless Covered by Health Insurance is Yes.'

  # dependent_items below tracks Yes/No source fields; this tracks their paired amount fields.
  INCOME_SOURCE_AMOUNT_FIELDS = GrdaWarehouse::Hud::IncomeBenefit::SOURCES.values.freeze

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
        :vha_services,
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
      # Form submission validation runs after IncomeBenefitProcessor assigns and derives HUD fields.
      # IncomeBenefitProcessor does a certain amount of manipulation to make sure the values make sense,
      # which should be duplicative with frontend autofill logic.
      # But here, we return validation errors if the user seems to have intentionally gotten into a weird state,
      # such as unsetting an autofilled Yes field without unsetting the dependent fields.

      # Income from Any Source is Yes, but no income sources are Yes
      if record.income_from_any_source == 1 && !dependent_yes_field_present?(record, :income_from_any_source)
        record.errors.add :income_from_any_source,
                          :invalid,
                          full_message: INCOME_SOURCES_UNSPECIFIED
      end

      if record.income_from_any_source != 1
        # Income from Any Source is not Yes, but total monthly income is positive
        if record.total_monthly_income.to_f.positive?
          record.errors.add :income_from_any_source,
                            :invalid,
                            full_message: INCOME_SOURE_WITHOUT_SUMMARY
        end

        # Income from Any Source is not Yes, but at least one source amount is positive.
        # (IncomeBenefitProcessor overrides these amounts, so this won't happen in practice)
        if INCOME_SOURCE_AMOUNT_FIELDS.any? { |field| record.public_send(field).to_f.positive? }
          record.errors.add :income_from_any_source,
                            :invalid,
                            full_message: INCOME_SOURE_WITHOUT_SUMMARY
        end
      end

      # Non-Cash Benefits from Any Source is Yes, but no benefits are Yes
      if record.benefits_from_any_source == 1 && !dependent_yes_field_present?(record, :benefits_from_any_source)
        record.errors.add :benefits_from_any_source,
                          :invalid,
                          full_message: BENEFIT_SOURCES_UNSPECIFIED
      end

      # Non-Cash Benefits from Any Source is not Yes, but at least one benefit is Yes
      if record.benefits_from_any_source != 1 && dependent_yes_field_present?(record, :benefits_from_any_source)
        record.errors.add :benefits_from_any_source,
                          :invalid,
                          full_message: BENEFIT_SOURCE_WITHOUT_SUMMARY
      end

      # Insurance from Any Source is Yes, but no insurance providers are Yes
      if record.insurance_from_any_source == 1 && !dependent_yes_field_present?(record, :insurance_from_any_source)
        record.errors.add :insurance_from_any_source,
                          :invalid,
                          full_message: INSURANCE_SOURCES_UNSPECIFIED
      end

      # Insurance from Any Source is not Yes, but at least one provider is Yes
      if record.insurance_from_any_source != 1 && dependent_yes_field_present?(record, :insurance_from_any_source)
        record.errors.add :insurance_from_any_source,
                          :invalid,
                          full_message: INSURANCE_SOURCE_WITHOUT_SUMMARY
      end
    end
  end

  protected

  # Returns true when at least one dependent Yes/No field for a summary field is HUD Yes (1).
  def dependent_yes_field_present?(record, summary_field)
    self.class.dependent_items[summary_field].any? { |field| record.public_send(field) == 1 }
  end
end
