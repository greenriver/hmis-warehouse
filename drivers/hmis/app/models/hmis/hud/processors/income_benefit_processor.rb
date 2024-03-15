###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis::Hud::Processors
  class IncomeBenefitProcessor < Base
    def process(field, value)
      attribute_name = ar_attribute_name(field)
      attribute_value = attribute_value_for_enum(graphql_enum(field), value)

      attributes = if field.end_with?('Amount')
        income_source_attributes(field, attribute_value)
      else
        attribute_value = 0 if override_to_no?(attribute_name, attribute_value)
        { attribute_name => attribute_value }
      end

      @processor.send(factory_name).assign_attributes(attributes)
    end

    def factory_name
      :income_benefit_factory
    end

    def relation_name
      :income_benefit
    end

    def schema
      Types::HmisSchema::IncomeBenefit
    end

    # For specific benefit/insurance fields, override Yes/No value based on "from any source" field
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

    # For specific income fields, set Yes/No value base on income amount.
    def income_source_attributes(amount_field, value)
      # Attribute for dollar amount (eg "unemployment_amount")
      amount_attribute_name = ar_attribute_name(amount_field)
      amount_attribute_value = value

      # Attribute for 0/1/99 status (eg "unemployment")
      bool_attribute_name = income_bool_field_name(amount_attribute_name)
      bool_attribute_value = nil

      case @hud_values['IncomeBenefit.incomeFromAnySource']
      when 'YES'
        # If overall income was 1 (yes), then this specific income field must be 1 or 0 (yes or no)
        bool_attribute_value = amount_attribute_value&.positive? ? 1 : 0
      when 'NO'
        # If overall income was 0 (no), then this specific income field is 0 (no)
        amount_attribute_value = nil
        bool_attribute_value = 0
      else
        # If overall income was 8/9/99, then this specific income field is 99 (not collected)
        amount_attribute_value = nil
        bool_attribute_value = 99
      end

      {
        amount_attribute_name => amount_attribute_value,
        bool_attribute_name => bool_attribute_value,
      }
    end

    def summary_item_dependents
      {
        'IncomeBenefit.incomeFromAnySource' => Hmis::Hud::Validators::IncomeBenefitValidator.dependent_items[:income_from_any_source],
        'IncomeBenefit.benefitsFromAnySource' => Hmis::Hud::Validators::IncomeBenefitValidator.dependent_items[:benefits_from_any_source],
        'IncomeBenefit.insuranceFromAnySource' => Hmis::Hud::Validators::IncomeBenefitValidator.dependent_items[:insurance_from_any_source],
      }
    end

    private def income_bool_field_name(field)
      return 'other_income_source' if field == 'other_income_amount'

      ar_attribute_name(field.sub(/_amount$/, ''))
    end
  end
end
