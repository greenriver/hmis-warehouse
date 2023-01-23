###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::QueryType < Types::BaseObject
    # From generated QueryType:
    # Add `node(id: ID!) and `nodes(ids: [ID!]!)`
    include GraphQL::Types::Relay::HasNodeField
    include GraphQL::Types::Relay::HasNodesField
    include Types::HmisSchema::HasProjects
    include Types::HmisSchema::HasOrganizations
    include Types::HmisSchema::HasClients

    projects_field :projects

    def projects(**args)
      resolve_projects(Hmis::Hud::Project.all, **args)
    end

    organizations_field :organizations

    def organizations(**args)
      resolve_organizations(Hmis::Hud::Organization.all, **args)
    end

    clients_field :client_search, 'Search for clients' do |field|
      field.argument :input, Types::HmisSchema::ClientSearchInput, required: true
    end

    def client_search(input:, **args)
      search_scope = Hmis::Hud::Client.client_search(input: input.to_params, user: current_user)
      resolve_clients(search_scope, **args)
    end

    field :client, Types::HmisSchema::Client, 'Client lookup', null: true do
      argument :id, ID, required: true
    end

    def client(id:)
      Hmis::Hud::Client.visible_to(current_user).find_by(id: id)
    end

    field :enrollment, Types::HmisSchema::Enrollment, 'Enrollment lookup', null: true do
      argument :id, ID, required: true
    end

    def enrollment(id:)
      Hmis::Hud::Enrollment.viewable_by(current_user).find_by(id: id)
    end

    field :organization, Types::HmisSchema::Organization, 'Organization lookup', null: true do
      argument :id, ID, required: true
    end

    def organization(id:)
      Hmis::Hud::Organization.viewable_by(current_user).find_by(id: id)
    end

    field :project, Types::HmisSchema::Project, 'Project lookup', null: true do
      argument :id, ID, required: true
    end

    def project(id:)
      Hmis::Hud::Project.viewable_by(current_user).find_by(id: id)
    end

    field :assessment, Types::HmisSchema::Assessment, 'Assessment lookup', null: true do
      argument :id, ID, required: true
    end

    def assessment(id:)
      Hmis::Hud::Assessment.viewable_by(current_user).find_by(id: id)
    end

    field :inventory, Types::HmisSchema::Inventory, 'Inventory lookup', null: true do
      argument :id, ID, required: true
    end

    def inventory(id:)
      Hmis::Hud::Inventory.viewable_by(current_user).find_by(id: id)
    end

    field :project_coc, Types::HmisSchema::ProjectCoc, 'Project CoC lookup', null: true do
      argument :id, ID, required: true
    end

    def project_coc(id:)
      Hmis::Hud::ProjectCoc.viewable_by(current_user).find_by(id: id)
    end

    field :funder, Types::HmisSchema::Funder, 'Funder lookup', null: true do
      argument :id, ID, required: true
    end

    def funder(id:)
      Hmis::Hud::Funder.viewable_by(current_user).find_by(id: id)
    end

    field :form_definition, Types::Forms::FormDefinition, 'Form definition lookup by identifier', null: true do
      argument :identifier, String, required: true
    end

    def form_definition(identifier:)
      Hmis::Form::Definition.where(identifier: identifier).order(version: :desc).first
    end

    field :get_form_definition, Types::Forms::FormDefinition, 'Get form definition for enrollment & assessment role', null: true do
      argument :enrollment_id, ID, required: true
      argument :assessment_role, Types::HmisSchema::Enums::AssessmentRole, required: true
    end

    def get_form_definition(enrollment_id:, assessment_role:)
      enrollment = Hmis::Hud::Enrollment.find_by(id: enrollment_id)
      definition = enrollment&.project&.present? ? Hmis::Form::Definition.find_definition_for_project(enrollment.project, role: assessment_role) : nil

      definition
    end

    field :pick_list, [Types::Forms::PickListOption], 'Get list of options for pick list', null: false do
      argument :pick_list_type, Types::Forms::Enums::PickListType, required: true
      argument :relation_id, ID, required: false
    end
    def pick_list(pick_list_type:, relation_id: nil)
      Types::Forms::PickListOption.options_for_type(pick_list_type, user: current_user, relation_id: relation_id)
    end
  end
end
