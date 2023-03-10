###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis::Hud::Processors
  class IncomeBenefitProcessor < Base
    def process(field, value)
      attribute_name = hud_name(field)
      attribute_value = attribute_value_for_enum(hud_type(field), value)
      attribute_value = 0 if override_to_no?(attribute_name, attribute_value)
      # binding.pry if field == 'earned'
      @processor.send(factory_name).assign_attributes(attribute_name => attribute_value)
    end

    def factory_name
      :income_benefit_factory
    end

    def schema
      Types::HmisSchema::IncomeBenefit
    end

    def override_to_no?(attribute_name, attribute_value)
      summary_item_dependents.each do |field_key, dependents|
        next unless dependents.include?(attribute_name.to_sym)

        # If summary item is NO, dependent item should also be NO
        return true if @hud_values[field_key] == 'NO'

        # If summary item is YES and dependent item is unanswered, dependent item should be NO
        return true if (attribute_value.nil? || attribute_value == 99) && @hud_values[field_key] == 'YES'
      end

      false
    end

    def summary_item_dependents
      {
        'IncomeBenefit.incomeFromAnySource' => [
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
        'IncomeBenefit.benefitsFromAnySource' => [
          :snap,
          :wic,
          :tanf_child_care,
          :tanf_transportation,
          :other_tanf,
          :other_benefits_source,
        ],
        'IncomeBenefit.insuranceFromAnySource' => [
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
  end
end
