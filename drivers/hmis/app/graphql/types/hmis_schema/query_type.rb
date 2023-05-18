###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
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
    include ::Hmis::Concerns::HmisArelHelper

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

    clients_field :client_omni_search, 'Client omnisearch' do |field|
      field.argument :text_search, String, 'Omnisearch string', required: true
    end

    def client_omni_search(text_search:, **args)
      client_order = Hmis::Hud::Client.searchable_to(current_user).matching_search_term(text_search).
        joins(:enrollments).
        merge(Hmis::Hud::Enrollment.open_during_range((Date.current - 1.month)..Date.current)).
        order(e_t[:date_updated].desc).
        pluck(:id, e_t[:date_updated]).
        map(&:first).
        uniq
      client_scope = Hmis::Hud::Client.where(id: client_order).order_as_specified(id: client_order)
      resolve_clients(client_scope, **args)
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
      Hmis::Hud::CustomAssessment.viewable_by(current_user).find_by(id: id)
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

    field :service, Types::HmisSchema::Service, 'Service lookup', null: true do
      argument :id, ID, required: true
    end

    def service(id:)
      Hmis::Hud::HmisService.viewable_by(current_user).find_by(id: id)
    end

    field :get_form_definition, Types::Forms::FormDefinition, 'Get most relevant/recent form definition for the specified Role and project (optionally)', null: true do
      argument :role, Types::Forms::Enums::FormRole, required: true
      argument :enrollment_id, ID, required: false
      argument :project_id, ID, required: false
    end

    field :file, Types::HmisSchema::File, null: true do
      argument :id, ID, required: true
    end

    def file(id:)
      Hmis::File.viewable_by(current_user).find_by(id: id)
    end

    def get_form_definition(role:, enrollment_id: nil, project_id: nil)
      project = Hmis::Hud::Project.find_by(id: project_id) if project_id.present?
      project = Hmis::Hud::Enrollment.find_by(id: enrollment_id)&.project if enrollment_id.present?

      Hmis::Form::Definition.find_definition_for_role(role, project: project)
    end

    field :get_service_form_definition, Types::Forms::FormDefinition, 'Get most relevant form definition for the specified service type', null: true do
      argument :custom_service_type_id, ID, required: true
      argument :enrollment_id, ID, required: true
    end
    def get_service_form_definition(custom_service_type_id:, enrollment_id:)
      project = Hmis::Hud::Enrollment.find_by(id: enrollment_id)&.project
      service_type = Hmis::Hud::CustomServiceType.find_by(id: custom_service_type_id)
      return unless project.present? && service_type.present?

      Hmis::Form::Definition.find_definition_for_service_type(service_type, project: project)
    end

    field :pick_list, [Types::Forms::PickListOption], 'Get list of options for pick list', null: false do
      argument :pick_list_type, Types::Forms::Enums::PickListType, required: true
      argument :relation_id, ID, required: false
    end
    def pick_list(pick_list_type:, relation_id: nil)
      Types::Forms::PickListOption.options_for_type(pick_list_type, user: current_user, relation_id: relation_id)
    end

    field :current_user, Application::User, null: true

    access_field do
      Hmis::Role.permissions_with_descriptions.keys.each do |perm|
        can perm, field_name: perm, method_name: perm, root: true
      end
    end

    def access
      {}
    end
  end
end
