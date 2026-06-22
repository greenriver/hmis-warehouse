###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::CeMatchRule < Types::BaseObject
    # object is a Hmis::Ce::Match::Rule

    available_filter_options do
      arg :owner_type, Types::HmisSchema::Enums::CeMatchRuleOwner
      arg :owner_id, ID
    end

    field :id, ID, null: false
    def id
      object.graphql_id || object.id
    end

    field :name, String, null: false
    field :owner_id, ID, null: false
    field :owner_name, String, null: false
    field :owner_type, Types::HmisSchema::Enums::CeMatchRuleOwner, null: false, description: 'Rule applies to projects within this related entity (eg a Data Source, Project, Organization), possibly limited by project type or funder'
    field :priority_rank, Integer, null: true
    field :rule_type, Types::HmisSchema::Enums::CeMatchRuleType, null: false
    field :expression, String, null: false
    field :structured_expression, Types::HmisSchema::CeMatchRuleStructuredExpression, null: true, description: 'Expression translated into a structured clause list; null if the expression is too complex to translate'
    field :project_types, [Types::HmisSchema::Enums::ProjectType], null: false, description: 'Rule applicability is limited to projects with these types'
    field :funders, [Types::HmisSchema::Enums::Hud::FundingSource], null: true, description: 'Rule applicability is limited to projects with these active funders'

    def owner_name
      return 'Global' if object.owner.is_a?(GrdaWarehouse::DataSource)

      object.owner.name
    end

    def project_types
      applicability_config = object.applicability_config.symbolize_keys
      applicability_config[:project_types] || []
    end

    def funders
      applicability_config = object.applicability_config.symbolize_keys
      applicability_config[:project_funders] || []
    end

    def structured_expression
      Hmis::Ce::Match::Expression::ExpressionTranslator.to_structured(object.expression)
    end
  end
end
