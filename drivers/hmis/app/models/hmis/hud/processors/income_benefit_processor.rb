###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis::Hud::Processors
  class IncomeBenefitProcessor < Base
    def process(field, value)
      attribute_name = ar_attribute_name(field)
      attribute_value = attribute_value_for_enum(graphql_enum(field), value)
      attribute_value = 0 if override_to_no?(attribute_name, attribute_value)

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
        'IncomeBenefit.incomeFromAnySource' => Hmis::Hud::Validators::IncomeBenefitValidator.dependent_items[:income_from_any_source],
        'IncomeBenefit.benefitsFromAnySource' => Hmis::Hud::Validators::IncomeBenefitValidator.dependent_items[:benefits_from_any_source],
        'IncomeBenefit.insuranceFromAnySource' => Hmis::Hud::Validators::IncomeBenefitValidator.dependent_items[:insurance_from_any_source],
      }
    end
  end
end
