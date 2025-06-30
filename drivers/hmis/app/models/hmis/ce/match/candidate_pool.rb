# frozen_string_literal: true

# Describes the eligibility requirements and prioritization for a client.

module Hmis::Ce::Match
  class CandidatePool < GrdaWarehouseBase
    self.table_name = 'ce_match_candidate_pools'
    has_many :candidates, class_name: 'Hmis::Ce::Match::Candidate', foreign_key: :candidate_pool_id, dependent: :destroy
    has_many :opportunities, class_name: 'Hmis::Ce::Opportunity', dependent: :restrict_with_exception

    def relevant_form_definition_identifiers
      # Gather relevant expressions for determining priority/eligibility in this candidate pool.
      # These look like: 'current_age > 18' or 'cde.custom_assessment.fieldname = 1'
      expressions = [requirement_expression, priority_expression]

      calculator = Hmis::Ce::Match::CalculatorFactory.build

      cde_fields = expressions.map do |expression|
        # For each expression, get the list of fields it references. E.g. ['current_age', 'cde.custom_assessment.fieldname']
        fields = calculator.dependencies(expression)

        fields.map do |field|
          # Use the FieldMap to map each field to its type, and skip if it isn't CDE
          field_type, resolved_field = Hmis::Ce::Match::FieldMap.field_type_for(field)
          next unless field_type == Hmis::Ce::Match::FieldMap::CDE

          resolved_field
        end.uniq
      end.flatten.compact.uniq

      # Gather all the CDEDs referenced by all CDE fields and return their form definition identifiers
      cdeds = Hmis::Ce::Match::CdeFieldMap.new.cdeds_for(cde_fields)
      cdeds.pluck(:form_definition_identifier).uniq
    end
  end
end
