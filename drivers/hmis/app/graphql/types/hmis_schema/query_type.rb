###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::QueryType < Types::BaseObject
    skip_activity_log

    # From generated QueryType:
    # Add `node(id: ID!) and `nodes(ids: [ID!]!)`
    include GraphQL::Types::Relay::HasNodeField
    include GraphQL::Types::Relay::HasNodesField
    include Types::HmisSchema::HasProjects
    include Types::HmisSchema::HasOrganizations
    include Types::HmisSchema::HasClients
    include Types::HmisSchema::HasApplicationUsers
    include Types::HmisSchema::HasReferralPostings
    include Types::Admin::HasFormRules
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
      # ensure that client search has sufficient search criteria, so as not to allow exposing all clients at once.
      # caller must use some search criteria, OR a service filter by project to limit results (used in Bulk Services)
      has_search_term = input.to_h.excluding(:projects, :organizations).values.compact_blank.any?
      has_service_filter = args[:filters]&.service_in_range&.project_id.present?
      raise 'Invalid search. At least 1 search param is required.' unless has_search_term || has_service_filter

      # if the search should also sort by rank
      sorted = args[:sort_order] == :best_match
      search_scope = Hmis::Hud::Client.client_search(
        input: input.to_params,
        user: current_user,
        sorted: sorted,
      )
      resolve_clients(search_scope, **args)
    end

    clients_field :client_omni_search, 'Client omnisearch' do |field|
      field.argument :text_search, String, 'Omnisearch string', required: true
    end

    def client_omni_search(text_search:)
      Hmis::Hud::Client.searchable_to(current_user).
        matching_search_term(text_search).
        sort_by_option(:recently_added)
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

    field :file, Types::HmisSchema::File, null: true do
      argument :id, ID, required: true
    end

    def file(id:)
      Hmis::File.viewable_by(current_user).find_by(id: id)
    end

    field :record_form_definition, Types::Forms::FormDefinition, 'Get the most relevant Form Definition to use for record viewing/editing', null: true do
      argument :role, Types::Forms::Enums::RecordFormRole, required: true
      argument :project_id, ID, required: false, description: 'Optional Project to select the relevant form, and to apply rule filtering (e.g. show/hide questions based on Project applicability)'
    end
    def record_form_definition(role:, project_id: nil)
      raise 'Not supported, use serviceFormDefinition to look up service forms' if role == 'SERVICE'
      raise 'unexpected role' unless Hmis::Form::Definition::FORM_ROLES.include?(role.to_sym)

      project = Hmis::Hud::Project.find_by(id: project_id) if project_id.present?
      record = Hmis::Form::Definition.find_definition_for_role(role, project: project)
      record&.filter_context = { project: project } # Apply project-specific filtering rules. Only relevant for some form types.
      record
    end

    field :assessment_form_definition, Types::Forms::FormDefinition, 'Get the correct Form Definition to use for an assessment, by Role or FormDefinition ID', null: true do
      argument :project_id, ID, required: true, description: 'Project to use for Rule filtering on the definition'
      argument :id, ID, required: false, description: 'Form Definition ID, if known'
      argument :role, Types::Forms::Enums::AssessmentRole, required: false, description: 'Assessment role, if looking up by role'
      argument :assessment_date, GraphQL::Types::ISO8601Date, required: false, description: 'Date to use for Rule filtering on the definition'
      validates required: { one_of: [:id, :role] }
    end
    def assessment_form_definition(project_id:, id: nil, role: nil, assessment_date: nil)
      raise 'id or role required' if id.nil? && role.nil?
      raise 'unexpected role' if role && !Hmis::Form::Definition::ASSESSMENT_FORM_ROLES.include?(role.to_sym)

      project = Hmis::Hud::Project.find(project_id)
      # Ensure that user can view enrollments for this project. There is no need to expose assessment forms otherwise.
      raise 'Access denied' unless current_user.can_view_enrollment_details_for?(project)

      if id
        # If ID is specified, we assume that it's correct for this project.
        record = Hmis::Form::Definition.find(id)
      else
        record = Hmis::Form::Definition.find_definition_for_role(role, project: project)
      end

      # Set filter context, so that form rules are applied
      record&.filter_context = { project: project, active_date: assessment_date }
      record
    end

    field :service_form_definition, Types::Forms::FormDefinition, 'Get most relevant form definition for the specified service type', null: true do
      argument :service_type_id, ID, required: true
      argument :project_id, ID, required: true
    end
    def service_form_definition(service_type_id:, project_id:)
      project = Hmis::Hud::Project.find_by(id: project_id)
      raise HmisErrors::ApiError, 'Project not found' unless project.present?

      service_type = Hmis::Hud::CustomServiceType.find_by(id: service_type_id)
      raise HmisErrors::ApiError, 'Service type not found' unless service_type.present?

      Hmis::Form::Definition.find_definition_for_service_type(service_type, project: project)
    end

    field :static_form_definition, Types::Forms::FormDefinition, null: false do
      argument :role, Types::Forms::Enums::StaticFormRole, required: true
    end
    def static_form_definition(role:)
      # Direct lookup for static form by role. Static forms don't require instances to enable them, since they are always present and non-configurable.
      # Assume that this is exactly 1 definition per static role
      Hmis::Form::Definition.order(:id).with_role(role).first!
    end

    field :parsed_form_definition, Types::Forms::FormDefinitionForJsonResult, null: true do
      argument :input, String, required: true
    end
    def parsed_form_definition(input:)
      json = JSON.parse(input)
      errors = Hmis::Form::DefinitionValidator.perform(json, skip_cded_validation: true)
      return { errors: errors.map(&:full_message) } if errors.any?

      { definition: json, errors: [] }
    end

    field :pick_list, [Types::Forms::PickListOption], 'Get list of options for pick list', null: false do
      argument :pick_list_type, Types::Forms::Enums::PickListType, required: true
      argument :project_id, ID, required: false
      argument :enrollment_id, ID, required: false
      argument :client_id, ID, required: false
      argument :household_id, ID, required: false
    end
    def pick_list(pick_list_type:, **args)
      Types::Forms::PickListOption.options_for_type(pick_list_type, user: current_user, **args)
    end

    field :current_user, Application::User, null: true

    access_field do
      Hmis::Role.permissions_with_descriptions.keys.each do |perm|
        root_can perm
      end
      field :can_view_my_dashboard, Boolean, null: false
    end

    def access
      {
        can_view_my_dashboard: current_user.can_view_my_dashboard?,
      }
    end

    field :referral_posting, Types::HmisSchema::ReferralPosting, null: true do
      argument :id, ID, required: true
    end

    def referral_posting(id:)
      posting = HmisExternalApis::AcHmis::ReferralPosting.viewable_by(current_user).find_by(id: id)

      # User must have access to manage incoming referrals at the project where this posting is referred to
      return unless posting && current_user.can_manage_incoming_referrals_for?(posting.project)

      posting
    end

    referral_postings_field :denied_pending_referral_postings
    def denied_pending_referral_postings(**args)
      raise 'Access denied' unless current_user.can_manage_denied_referrals?

      postings = HmisExternalApis::AcHmis::ReferralPosting.where(status: [:denied_pending_status, :denied_status])

      scoped_referral_postings(postings, **args)
    end

    field :merge_candidates, Types::HmisSchema::ClientMergeCandidate.page_type, null: false
    def merge_candidates
      raise 'Access denied' unless current_user.can_merge_clients?

      # Find all destination clients that have more than 1 source client in the HMIS
      destination_ids_with_multiple_sources = GrdaWarehouse::WarehouseClient.
        where(data_source_id: current_user.hmis_data_source_id).
        joins(:source). # drop non existent source clients
        group(:destination_id).
        having('count(*) > 1').
        pluck(:destination_id)

      # Resolve each destination client as a ClientMergeCandidate
      Hmis::Hud::Client.where(id: destination_ids_with_multiple_sources)
    end

    application_users_field :application_users
    def application_users(**args)
      raise 'Access denied' unless current_user.can_audit_users? || current_user.can_impersonate_users?

      resolve_application_users(Hmis::User.active.with_hmis_access, **args)
    end

    field :user, Types::Application::User, 'User lookup', null: true do
      argument :id, ID, required: true
    end
    def user(id:)
      raise 'Access denied' unless id == current_user.id.to_s || current_user.can_audit_users? || current_user.can_impersonate_users?

      load_ar_scope(scope: Hmis::User.with_hmis_access, id: id)
    end

    field :merge_audit_history, Types::HmisSchema::MergeAuditEvent.page_type, null: false do
      filters_argument Types::HmisSchema::MergeAuditEvent
    end
    def merge_audit_history(filters: nil)
      raise 'Access denied' unless current_user.can_merge_clients?

      scope = Hmis::ClientMergeAudit.all
      scope = scope.apply_filters(filters) if filters
      scope.order(merged_at: :desc)
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

    field :service_category, Types::HmisSchema::ServiceCategory, null: true do
      argument :id, ID, required: true
    end
    def service_category(id:)
      raise 'Access denied' unless current_user.can_configure_data_collection?

      Hmis::Hud::CustomServiceCategory.find_by(id: id)
    end

    field :service_categories, Types::HmisSchema::ServiceCategory.page_type, null: false
    def service_categories
      raise 'Access denied' unless current_user.can_configure_data_collection?

      # TODO: add sort and filter capabilities
      Hmis::Hud::CustomServiceCategory.all
    end

    field :service_types, Types::HmisSchema::ServiceType.page_type, null: false do
      filters_argument HmisSchema::ServiceType
    end
    def service_types(filters: nil)
      raise 'Access denied' unless current_user.can_configure_data_collection?

      scope = Hmis::Hud::CustomServiceType.all
      scope = scope.apply_filters(filters) if filters
      scope.order(:name, :id)
    end

    field :form_definition, Types::Forms::FormDefinition, null: true do
      argument :id, ID, required: true
    end
    def form_definition(id:)
      # NOTE: this query is only used for form management. It probably should
      # not be used for the application, because there is no project context passed
      # to the definition.
      access_denied! unless current_user.can_configure_data_collection?

      Hmis::Form::Definition.find(id)
    end

    field :external_form_definition, Types::Forms::FormDefinition, null: true, deprecation_reason: 'use definition from the individual submission to display' do
      argument :identifier, String, required: true
    end
    def external_form_definition(identifier:)
      raise 'Access denied' unless current_user.can_manage_external_form_submissions?

      Hmis::Form::Definition.with_role(:EXTERNAL_FORM).where(identifier: identifier).order(version: :desc).first
    end

    field :external_form_submission, Types::HmisSchema::ExternalFormSubmission, null: true do
      argument :id, ID, required: true
    end
    def external_form_submission(id:)
      raise 'Access denied' unless current_user.can_manage_external_form_submissions?

      HmisExternalApis::ExternalForms::FormSubmission.find(id)
    end

    field :form_identifier, Types::Forms::FormIdentifier, null: true do
      argument :identifier, String, required: true
    end
    def form_identifier(identifier:)
      access_denied! unless current_user.can_configure_data_collection?

      Hmis::Form::Definition.non_static.latest_versions.where(identifier: identifier).first
    end

    field :form_identifiers, Types::Forms::FormIdentifier.page_type, null: false do
      filters_argument Forms::FormIdentifier
    end
    def form_identifiers(filters: nil)
      access_denied! unless current_user.can_configure_data_collection?

      scope = Hmis::Form::Definition.non_static.valid.latest_versions
      scope = scope.with_role(Hmis::Form::Definition::NON_ADMIN_FORM_ROLES) unless current_user.can_administrate_config?
      scope = scope.apply_filters(filters) if filters
      scope.order(updated_at: :desc)
    end

    form_rules_field
    def form_rules(**args)
      access_denied! unless current_user.can_configure_data_collection?

      scope = Hmis::Form::Instance.all
      scope = scope.with_role(Hmis::Form::Definition::NON_ADMIN_FORM_ROLES) unless current_user.can_administrate_config?

      resolve_form_rules(scope, **args)
    end

    field :form_rule, Types::Admin::FormRule, null: true do
      argument :id, ID, required: true
    end
    def form_rule(id:)
      access_denied! unless current_user.can_configure_data_collection?

      Hmis::Form::Instance.find_by(id: id)
    end

    field :project_configs, Types::HmisSchema::ProjectConfig.page_type, null: false
    def project_configs
      raise 'not allowed' unless current_user.can_configure_data_collection?

      Hmis::ProjectConfig.all
    end

    field :project_can_accept_referral, Boolean, 'Whether the destination project is able to accept a referral for the client(s) belonging to the source enrollment', null: false do
      argument :destination_project_id, ID, required: true
      argument :source_enrollment_id, ID, required: true
    end
    def project_can_accept_referral(destination_project_id:, source_enrollment_id:)
      source_enrollment = Hmis::Hud::Enrollment.viewable_by(current_user).find(source_enrollment_id)
      raise 'access denied' unless current_permission?(permission: :can_manage_outgoing_referrals, entity: source_enrollment.project)

      # This doesn't check viewable_by! Users are able to ask whether the project receiving referrals can accept
      # this client, even if they don't otherwise have permission to view the project or its enrollments.
      # This is an acceptable permission leak because:
      # - it is only available for projects that receive referrals
      # - it is only available to users who can manage outgoing referrals
      # - it doesn't expose any info about the actual enrollment(s), just a yes/no
      project = Hmis::Hud::Project.find_by(id: destination_project_id)
      raise 'access denied' unless project.receives_referrals?

      # Can't accept the referral if any client in the household has an existing open enrollment in the project.
      personal_ids = source_enrollment.household_members.pluck(:PersonalID)

      # This doesn't check viewable_by either, see comment above
      !project.enrollments.open_including_wip.where(personal_id: personal_ids).exists?
    end

    field :client_detail_forms, [Types::HmisSchema::OccurrencePointForm], null: false, description: 'Custom forms for collecting and/or displaying custom details for a Client (outside of the Client demographics form)'
    def client_detail_forms
      # No authorization required, this just resolving application configuration
      Hmis::Form::Instance.active.with_role(:CLIENT_DETAIL).sort_by_option(:form_title)
    end
  end
end
