###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::CeMatchRuleStructuredExpression < Types::BaseObject
    # object is a Hmis::Ce::Match::Expression::StructuredExpression,
    # which gives structure to the free-text string `expression` from a Hmis::Ce::Match::Rule.
    # For now, this graphql type can only represent a flat list of clauses joined by AND or OR.
    # If the expression isn't representable as a flat list, such as (A and B) or (C and D),
    # then this type will be null and the frontend will fall back to rendering the free-text expression
    # (with more limited edit capabilities).

    field :operator, Types::HmisSchema::Enums::CeMatchRuleBooleanOperator, null: false
    field :clauses, [Types::HmisSchema::CeMatchRuleClause], null: false

    def operator
      object.operator.to_s
    end
  end
end
