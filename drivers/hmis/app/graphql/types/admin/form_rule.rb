###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class Admin::FormRule < Types::BaseObject
    # maps to Hmis::Form::Instance
    graphql_name 'FormRule'

    available_filter_options do
      arg :form_type, [Types::Forms::Enums::FormRole] # FIXME: static roles should be excluded
      arg :active_status, [Types::HmisSchema::Enums::ActiveStatus]
      arg :system_form, [Types::HmisSchema::Enums::SystemStatus]
      arg :project_type, [Types::HmisSchema::Enums::ProjectType]
      arg :applied_to_project, ID
      arg :definition, ID
      arg :service_type, ID
      arg :service_category, ID
    end

    field :id, ID, null: false
    # Form Definition info
    field :definition_identifier, String, null: false
    field :definition_id, ID, null: true
    field :definition_role, Types::Forms::Enums::FormRole, null: true
    field :definition_title, String, null: true
    # Applicability rule fields
    field :project_type, Types::HmisSchema::Enums::ProjectType, null: true
    field :funder, Types::HmisSchema::Enums::Hud::FundingSource, null: true
    field :other_funder, String, null: true
    field :organization_id, ID, null: true
    field :organization, HmisSchema::Organization, null: true
    field :project_id, ID, null: true
    field :project, HmisSchema::Project, null: true
    field :service_category, HmisSchema::ServiceCategory, null: true, method: :custom_service_category
    field :service_type, HmisSchema::ServiceType, null: true, method: :custom_service_type
    field :data_collected_about, Types::Forms::Enums::DataCollectedAbout, null: true
    # Status and metadata
    field :active, Boolean, null: false
    field :active_status, Types::HmisSchema::Enums::ActiveStatus, null: false
    field :system, Boolean, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

    # TODO ADD: list of projects that this rule ends up being applied to

    def definition_id
      load_ar_association(object, :definition)&.id
    end

    def definition_role
      load_ar_association(object, :definition)&.role
    end

    def definition_title
      load_ar_association(object, :definition)&.title
    end

    def project_id
      return unless object.entity_type == Hmis::Hud::Project.sti_name

      object.entity_id
    end

    def project
      return unless object.entity_type == Hmis::Hud::Project.sti_name

      object.entity
    end

    def organization_id
      return unless object.entity_type == Hmis::Hud::Organization.sti_name

      object.entity_id
    end

    def organization
      return unless object.entity_type == Hmis::Hud::Organization.sti_name

      object.entity
    end

    def active_status
      object.active ? 'ACTIVE' : 'INACTIVE'
    end
  end
end
