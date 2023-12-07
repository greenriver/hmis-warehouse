###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class Admin::FormRule < Types::BaseObject
    # maps to Hmis::Form::Instance
    graphql_name 'FormRule'

    available_filter_options do
      arg :form_type, [Types::Forms::Enums::FormRole]
      arg :active_status, [Types::HmisSchema::Enums::ActiveStatus]
      arg :system_form, [Types::HmisSchema::Enums::SystemStatus]
      arg :service_category, [ID]
      arg :project_type, [Types::HmisSchema::Enums::ProjectType]
      arg :applied_to_project, ID
    end

    field :id, ID, null: false
    field :definition_identifier, String, null: false
    field :definition_id, ID, null: true
    field :definition_role, Types::Forms::Enums::FormRole, null: true
    field :definition_title, String, null: true

    # field :definition, Types::Forms::FormDefinition, null: false

    # Applicability fields
    field :project, HmisSchema::Project, null: true
    field :organization, HmisSchema::Organization, null: true
    field :service_category, HmisSchema::ServiceCategory, null: true, method: :custom_service_category
    field :service_type, HmisSchema::ServiceType, null: true, method: :custom_service_type
    field :funder, Types::HmisSchema::Enums::Hud::FundingSource, null: true
    field :other_funder, String, null: true
    field :project_type, Types::HmisSchema::Enums::ProjectType, null: true
    field :data_collected_about, Types::Forms::Enums::DataCollectedAbout, null: true

    field :system, Boolean, null: false
    field :active, Boolean, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

    def definition_id
      load_ar_association(object, :definition)&.id
    end

    def definition_role
      load_ar_association(object, :definition)&.role
    end

    def definition_title
      load_ar_association(object, :definition)&.title
    end

    def project
      return unless object.entity_type == Hmis::Hud::Project.sti_name

      object.entity
    end

    def organization
      return unless object.entity_type == Hmis::Hud::Organization.sti_name

      object.entity
    end
  end
end
