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
    include Types::HmisSchema::HasReferralPostings
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

    def client_omni_search(text_search:)
      client_scope = Hmis::Hud::Client.searchable_to(current_user).
        matching_search_term(text_search).
        includes(:enrollments).
        order(qualified_column(e_t[:date_updated]))

      resolve_clients(client_scope, no_sort: true)
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

    field :household, Types::HmisSchema::Household, 'Household lookup', null: true do
      argument :id, ID, required: true
    end

    def household(id:)
      Hmis::Hud::Household.viewable_by(current_user).find_by(household_id: id, data_source_id: current_user.hmis_data_source_id)
    end

    field :household_assessments, [Types::HmisSchema::Assessment], 'Get group of assessments that are performed together', null: true do
      argument :household_id, ID, required: true
      argument :assessment_role, Types::Forms::Enums::AssessmentRole, required: true
      argument :assessment_id, ID, required: false
    end

    def household_assessments(household_id:, assessment_role:, assessment_id: nil)
      enrollments = Hmis::Hud::Enrollment.viewable_by(current_user).where(household_id: household_id)
      raise HmisErrors::ApiError, 'Access denied' unless enrollments.present?

      Hmis::Hud::CustomAssessment.group_household_assessments(
        household_enrollments: enrollments,
        assessment_role: assessment_role,
        assessment_id: assessment_id,
        threshold: 3.months,
      )
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

    field :service_type, Types::HmisSchema::ServiceType, 'Service type lookup', null: true do
      argument :id, ID, required: true
    end
    def service_type(id:)
      Hmis::Hud::CustomServiceType.find_by(id: id)
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
      argument :service_type_id, ID, required: true
      argument :project_id, ID, required: true
    end
    def get_service_form_definition(service_type_id:, project_id:)
      project = Hmis::Hud::Project.find_by(id: project_id)
      raise HmisErrors::ApiError, 'Project not found' unless project.present?

      service_type = Hmis::Hud::CustomServiceType.find_by(id: service_type_id)
      raise HmisErrors::ApiError, 'Service type not found' unless service_type.present?

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
        root_can perm
      end
    end

    def access
      {}
    end

    field :referral_posting, Types::HmisSchema::ReferralPosting, null: true do
      argument :id, ID, required: true
    end

    def referral_posting(id:)
      HmisExternalApis::AcHmis::ReferralPosting.viewable_by(current_user).find_by(id: id)
    end

    referral_postings_field :denied_pending_referral_postings
    def denied_pending_referral_postings(**args)
      return [] unless current_user.can_manage_denied_referrals?

      postings = HmisExternalApis::AcHmis::ReferralPosting.denied_pending_status

      scoped_referral_postings(postings, **args)
    end

    # AC HMIS Queries

    field :esg_funding_report, [Types::AcHmis::EsgFundingService], null: false do
      argument :client_ids, [ID], required: true
    end

    def esg_funding_report(client_ids:)
      cst = Hmis::Hud::CustomServiceType.where(name: 'ESG Funding Assistance').first!
      raise HmisErrors::ApiError, 'ESG Funding Assistance service not configured' unless cst.present?

      clients = Hmis::Hud::Client.adults.viewable_by(current_user).where(id: client_ids)

      # NOTE: Purposefully does not call `viewable_by`, as the report must include the full service history
      Hmis::Hud::CustomService.
        joins(:client).
        merge(clients).
        where(custom_service_type: cst, data_source_id: current_user.hmis_data_source_id).
        preload(:project, :client, :organization)
    end
  end
end
