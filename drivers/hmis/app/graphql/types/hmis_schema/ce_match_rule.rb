###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::CeMatchRule < Types::BaseObject
    # object is a Hmis::Ce::Match::Rule

    field :id, ID, null: false
    field :name, String, null: false
    field :owner_type, String, null: false, description: 'Rule applies to all projects within this related entity (eg a Data Source, Project, Organization)'
    field :expression, String, null: false
    field :project_types, [Types::HmisSchema::Enums::ProjectType], null: false, description: 'Rule applicability is limited to projects with these types'
    field :funders, [Types::HmisSchema::Enums::Hud::FundingSource], null: true, description: 'Rule applicability is limited to projects with these active funders'

    def owner_type
      object.owner_type.demodulize.underscore.titleize
    end

    def project_types
      applicability_config = object.applicability_config.symbolize_keys
      applicability_config[:project_types] || []
    end

    def funders
      applicability_config = object.applicability_config.symbolize_keys
      applicability_config[:project_funders] || []
    end
  end
end
