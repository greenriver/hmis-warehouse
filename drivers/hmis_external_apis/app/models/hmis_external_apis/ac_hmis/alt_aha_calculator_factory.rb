###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisExternalApis::AcHmis
  # Builds the Alt-AHA calculator for the model version this environment scores with
  # (HmisExternalApis::AcHmis::Configuration#alt_aha_model_version). Both calculators answer
  # calculate_score and required_link_ids.
  class AltAhaCalculatorFactory
    def self.build(definition:, values_by_link_id:, client:, user: nil, owner: nil)
      model_version = HmisExternalApis::AcHmis.configuration.alt_aha_model_version
      check_rules_fit_definition!(model_version, definition)

      if calculator_class(model_version) == AltAhaV2Calculator
        AltAhaV2Calculator.new(values_by_link_id: values_by_link_id, client: client, definition: definition, user: user, owner: owner)
      else
        AltAhaCalculator.new(values_by_link_id: values_by_link_id, client: client, user: user, owner: owner, form_definition_identifier: definition.identifier)
      end
    end

    # Checks a model version's rules for the definition's identifier against that definition.
    # Also used by the validate_alt_aha_rules task.
    def self.rule_validator(model_version, definition)
      calculator_class = calculator_class(model_version)
      Hmis::Scoring::RuleValidator.new(
        rules: Hmis::Scoring::Rule.for_form(definition.identifier).where(model_version: model_version).order(:id),
        definition: definition,
        ignored_link_ids: [calculator_class::CLIENT_AGE_LINK_ID, calculator_class::CLIENT_GENDER_LINK_ID],
      )
    end

    def self.calculator_class(model_version)
      model_version == 2 ? AltAhaV2Calculator : AltAhaCalculator
    end
    private_class_method :calculator_class

    # Rules for questions missing from the form would score silently wrong: validate_form_values skips required
    # link_ids that are not on the definition, and the calculator treats them as unanswered. This happens when the
    # configured model version and the published form disagree, such as between publishing a form and switching the version.
    def self.check_rules_fit_definition!(model_version, definition)
      missing = rule_validator(model_version, definition).missing_link_ids
      return if missing.empty?

      raise "Alt-AHA model version #{model_version} rules for #{definition.identifier} reference questions not on form definition #{definition.id}: #{missing.sort.join(', ')}"
    end
    private_class_method :check_rules_fit_definition!
  end
end
