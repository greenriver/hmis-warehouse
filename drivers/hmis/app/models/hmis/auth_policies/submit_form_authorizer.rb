###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Note: This is not a policy, but an authorization helper.
# It's colocated with the policies since it is logically related to them.
# It both builds new records and authorizes form submission on create or edit.
# Returns the authorized record; raises HmisErrors::ApiError if unauthorized.
class Hmis::AuthPolicies::SubmitFormAuthorizer
  # Enrollment-related records: authorization delegates to the enrollment policy
  ENROLLMENT_RELATED_CLASSES = [
    'Hmis::Hud::CurrentLivingSituation',
    'Hmis::Hud::Assessment',
    'Hmis::Hud::CustomCaseNote',
    'Hmis::Hud::Event',
  ].freeze

  # Project-related records: authorization delegates to the project policy
  PROJECT_RELATED_CLASSES = [
    'Hmis::Hud::Funder',
    'Hmis::Hud::ProjectCoc',
    'Hmis::Hud::Inventory',
    'Hmis::Hud::CeParticipation',
    'Hmis::Hud::HmisParticipation',
  ].freeze

  # Returns the authorized record. Raises HmisErrors::ApiError if not found or unauthorized.
  def self.authorized_record(user:, definition:, input:)
    new(user: user, definition: definition, input: input).send(:authorized_record)
  end

  def initialize(user:, definition:, input:)
    @user = user
    @klass = definition.owner_class
    @form_role = definition.role.to_sym
    @input = input

    if input.record_id
      @record = find_existing_record(input.record_id)
    else
      @creating = true

      # Resolve associations if provided in input
      @project = Hmis::Hud::Project.viewable_by(@user).find_by(id: @input.project_id) if @input.project_id.present?
      @client = Hmis::Hud::Client.viewable_by(@user).find_by(id: @input.client_id) if @input.client_id.present?
      @enrollment = Hmis::Hud::Enrollment.viewable_by(@user).find_by(id: @input.enrollment_id) if @input.enrollment_id.present?
      @organization = Hmis::Hud::Organization.viewable_by(@user).find_by(id: @input.organization_id) if @input.organization_id.present?
      @custom_service_type = Hmis::Hud::CustomServiceType.find_by(id: @input.service_type_id) if @input.service_type_id.present?
    end
  end

  private

  def authorized_record
    case @klass.name
    when 'Hmis::Hud::Client'
      client_record
    when 'Hmis::Hud::Organization'
      organization_record
    when 'Hmis::Hud::Project'
      project_record
    when 'Hmis::Hud::Enrollment'
      enrollment_record
    when *PROJECT_RELATED_CLASSES
      project_related_record
    when 'Hmis::Hud::HmisService'
      hmis_service_record
    when *ENROLLMENT_RELATED_CLASSES
      enrollment_related_record
    when 'HmisExternalApis::AcHmis::ReferralRequest'
      raise 'ReferralRequest form submission is no longer supported'
    when 'HmisExternalApis::AcHmis::ReferralPosting'
      referral_posting_record
    when 'Hmis::File'
      file_record
    else
      raise "No authorization configured for #{@klass.name}"
    end
  end

  def client_record
    if @creating
      access_denied! unless @user.policy_for(Hmis::Hud::Client, policy_type: :hmis_client).can_create?

      @klass.new(ds)
    else
      access_denied! unless @user.policy_for(@record, policy_type: :hmis_client).can_edit?

      @record
    end
  end

  def organization_record
    if @creating
      access_denied! unless @user.policy_for(Hmis::Hud::Organization, policy_type: :hmis_organization).can_create?

      @klass.new(ds)
    else
      access_denied! unless @user.policy_for(@record, policy_type: :hmis_organization).can_edit?

      @record
    end
  end

  def project_record
    if @creating
      access_denied! unless @organization.present?
      access_denied! unless @user.policy_for(@organization, policy_type: :hmis_organization).can_create_project?

      @klass.new(
        **ds,
        organization_id: @organization&.organization_id,
        project_id: @klass.generate_uuid, # Generate project ID so that related records created using nested attributes will be valid
      )
    else
      access_denied! unless @user.policy_for(@record, policy_type: :hmis_project).can_edit?

      @record
    end
  end

  def enrollment_record
    if @creating
      access_denied! unless @project.present?
      access_denied! unless @user.policy_for(@project, policy_type: :hmis_project).can_enroll_clients?

      if @form_role == :NEW_CLIENT_ENROLLMENT
        # New Client Enrollment form creates both an Enrollment and a Client record, so authorize both
        access_denied! unless @user.policy_for(Hmis::Hud::Client, policy_type: :hmis_client).can_create?
      end

      @klass.new(project_id: @project&.project_id, project_pk: @project&.id, personal_id: @client&.personal_id, **ds)
    else
      access_denied! unless @user.policy_for(@record, policy_type: :hmis_enrollment).can_edit?

      @record
    end
  end

  def project_related_record
    if @creating
      access_denied! unless @project.present?
      access_denied! unless @user.policy_for(@project, policy_type: :hmis_project).can_edit?

      @klass.new(project_id: @project&.project_id, **ds)
    else
      access_denied! unless @user.policy_for(@record.project, policy_type: :hmis_project).can_edit?

      @record
    end
  end

  def hmis_service_record
    if @creating
      raise 'cannot create service without custom service type' unless @custom_service_type.present?

      access_denied! unless @enrollment.present?
      access_denied! unless @user.policy_for(@enrollment, policy_type: :hmis_enrollment).can_edit?

      attrs = { enrollment_id: @enrollment&.enrollment_id, personal_id: @enrollment&.personal_id, **ds }
      if @custom_service_type.hud_service?
        Hmis::Hud::Service.new(record_type: @custom_service_type.hud_record_type, type_provided: @custom_service_type.hud_type_provided, **attrs)
      else
        Hmis::Hud::CustomService.new(custom_service_type: @custom_service_type, **attrs)
      end
    else
      access_denied! unless @user.policy_for(@record.enrollment, policy_type: :hmis_enrollment).can_edit?

      @record
    end
  end

  def enrollment_related_record
    if @creating
      access_denied! unless @enrollment.present?
      access_denied! unless @user.policy_for(@enrollment, policy_type: :hmis_enrollment).can_edit?

      @klass.new(personal_id: @enrollment&.personal_id, enrollment_id: @enrollment&.enrollment_id, **ds)
    else
      access_denied! unless @user.policy_for(@record.enrollment, policy_type: :hmis_enrollment).can_edit?

      @record
    end
  end

  def referral_posting_record
    if @creating
      receiving_project = Hmis::Hud::Project.find_by(id: @input.project_id)
      access_denied! unless @enrollment.present? && receiving_project.present?

      source_project = @enrollment.project
      access_denied! unless @user.policy_for(source_project, policy_type: :hmis_project).can_send_out_direct_referral?

      HmisExternalApis::AcHmis::ReferralPosting.new_with_referral(
        enrollment: @enrollment,
        receiving_project: receiving_project,
        user: @user,
      )
    else
      source_project = @record.referral.enrollment.project
      access_denied! unless @user.policy_for(source_project, policy_type: :hmis_project).can_send_out_direct_referral?

      @record
    end
  end

  def file_record
    if @creating
      access_denied! unless @client.present?
      access_denied! unless Hmis::File.authorize_proc.call(@client, @user)

      @klass.new(client_id: @client&.id, enrollment_id: @enrollment&.id)
    else
      access_denied! unless Hmis::File.authorize_proc.call(@record, @user)

      @record
    end
  end

  def access_denied!
    raise HmisErrors::ApiError, 'access denied'
  end

  def ds
    { data_source_id: @user.hmis_data_source_id }
  end

  def find_existing_record(record_id)
    record = @klass.viewable_by(@user).find_by(id: record_id)
    record = record.owner if record.is_a?(Hmis::Hud::HmisService)
    raise HmisErrors::ApiError, 'Record not found' unless record.present?

    record
  end
end
