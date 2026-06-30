###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::CeMatchRuleClause < Types::BaseObject
    # underlying object is a Hmis::Ce::Match::Expression::StructuredExpression::Clause

    field :field, String, null: false, description: 'The name of the field for comparison, such as client_age or cde.custom_assessment.my_score'
    field :field_source, Types::HmisSchema::Enums::CeMatchRuleFieldSource, null: false
    field :form_definition_identifier, String, null: true
    field :comparator, Types::HmisSchema::Enums::CeMatchRuleComparator, null: false, description: 'The comparison operator to apply to the field and value, such as EQ'
    field :value, GraphQL::Types::JSON, null: true, description: 'The value to compare the field against, such as 18 or "1 Bed". JSON scalar (e.g. integer, float, string, boolean, or null). Not a list or nested object.'

    def comparator
      object.comparator.to_s
    end

    def field_source
      object.field_source.to_s
    end

    def form_definition_identifier
      object.form_definition_identifier
    end
  end
end
