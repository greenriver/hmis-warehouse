###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::CeMatchRuleClauseInput < BaseInputObject
    argument :field, String, required: true
    argument :comparator, Types::HmisSchema::Enums::CeMatchRuleComparator, required: true
    argument :value, GraphQL::Types::JSON, required: false

    def to_structured_clause
      Hmis::Ce::Match::Expression::StructuredExpression::Clause.new(
        field: field,
        comparator: comparator,
        value: value,
      )
    end
  end
end
