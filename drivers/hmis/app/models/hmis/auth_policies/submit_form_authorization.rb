###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Note: This is not a policy, but an authorization helper.
# It's colocated with the policies since it is logically related to them.
# It maps form definitions and resource types to the appropriate policy checks.
class Hmis::AuthPolicies::SubmitFormAuthorization
  # Enrollment-related records: authorization delegates to the enrollment policy
  ENROLLMENT_RELATED_CLASSES = [
    'Hmis::Hud::Service',
    'Hmis::Hud::CustomService',
    'Hmis::Hud::HmisService',
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

  def self.can_submit?(user:, resource:)
    new(user: user, resource: resource).authorized?
  end

  def initialize(user:, resource:)
    @user = user
    @resource = resource
  end

  # Answers the question: Can the user submit this form to create/edit this resource?
  # Resource may be anything that can be submitted via a form -- client, project, enrollment, etc.
  # Resource may be a new, unpersisted record or an existing persisted record.
  def authorized?
    resource_class = @resource.class.name
    creating = @resource.new_record?

    case resource_class
    when 'Hmis::Hud::Client'
      client_authorized?(creating)
    when 'Hmis::Hud::Organization'
      organization_authorized?(creating)
    when 'Hmis::Hud::Project'
      project_authorized?(creating)
    when *PROJECT_RELATED_CLASSES
      project = @resource.project
      @user.policy_for(project, policy_type: :hmis_project).can_edit?
    when 'Hmis::Hud::Enrollment'
      enrollment_authorized?(creating)
    when *ENROLLMENT_RELATED_CLASSES
      enrollment = enrollment_for_resource
      @user.policy_for(enrollment, policy_type: :hmis_enrollment).can_edit?
    when 'HmisExternalApis::AcHmis::ReferralPosting'
      # Check outgoing referral permission against the source (submitting) project
      source_project = @resource.referral.enrollment.project
      @user.policy_for(source_project, policy_type: :hmis_project).can_send_out_direct_referral?
    when 'HmisExternalApis::ExternalForms::FormSubmission'
      # External form submissions are only edited (never created) via SubmitForm.
      @user.policy_for(@resource.project, policy_type: :hmis_project).can_manage_external_form_submissions?
    when 'Hmis::File'
      # Files have custom authorization handled by the File model's authorize_proc
      entity_base = @resource.new_record? ? @resource.client : @resource
      Hmis::File.authorize_proc.call(entity_base, @user)
    else
      raise "No authorization configured for #{resource_class}"
    end
  end

  private

  def client_authorized?(creating)
    if creating
      @user.policy_for(Hmis::Hud::Client, policy_type: :hmis_client).can_create?
    else
      @user.policy_for(@resource, policy_type: :hmis_client).can_edit?
    end
  end

  def organization_authorized?(creating)
    if creating
      @user.policy_for(Hmis::Hud::Organization, policy_type: :hmis_organization).can_create?
    else
      @user.policy_for(@resource, policy_type: :hmis_organization).can_edit?
    end
  end

  def project_authorized?(creating)
    if creating
      # todo @martha - organization is available yet on the project(?)
      @user.policy_for(@resource.organization, policy_type: :hmis_organization).can_create_project?
    else
      @user.policy_for(@resource, policy_type: :hmis_project).can_edit?
    end
  end

  def enrollment_authorized?(creating)
    if creating
      # Creating an enrollment requires permission to enroll clients in the target project
      # todo @martha - project is available on the enrollment?
      @user.policy_for(@resource.project, policy_type: :hmis_project).can_enroll_clients?
    else
      @user.policy_for(@resource, policy_type: :hmis_enrollment).can_edit?
    end
  end

  def enrollment_for_resource
    # HmisService is a view model; delegate to its underlying owner record
    # todo @martha- spec this and understand what it maps to from the previous code
    resource = @resource.is_a?(Hmis::Hud::HmisService) ? @resource.owner : @resource
    resource.enrollment
  end
end
