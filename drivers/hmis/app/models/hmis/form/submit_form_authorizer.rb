###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# SubmitFormAuthorizer finds or builds the record for form submission and authorizes the action.
# - Edit path: find existing record by record_id, authorize edit
# - Create path: build record via SubmitFormRecordInitializer, authorize create
#
# Usage: Hmis::Form::SubmitFormAuthorizer.authorized_record(user:, definition:, input:)
class Hmis::Form::SubmitFormAuthorizer
  attr_reader :user, :klass, :form_role

  ENROLLMENT_RELATED_CLASSES = Hmis::Form::SubmitFormRecordInitializer::ENROLLMENT_RELATED_CLASSES
  PROJECT_RELATED_CLASSES = Hmis::Form::SubmitFormRecordInitializer::PROJECT_RELATED_CLASSES

  # Returns the authorized record. Raises if not found or unauthorized.
  def self.authorized_record(user:, definition:, input:)
    new(user: user, definition: definition).call(input)
  end

  def initialize(user:, definition:)
    @user = user
    @klass = definition.owner_class
    @form_role = definition.role.to_sym
  end

  def authorized_to_create?(record)
    raise 'expected record to be a new record' unless record.new_record?

    case record.class.name
    when 'Hmis::Hud::Client'
      user.policy_for(Hmis::Hud::Client, policy_type: :hmis_client).can_create?
    when 'Hmis::Hud::Organization'
      user.policy_for(Hmis::Hud::Organization, policy_type: :hmis_organization).can_create?
    when 'Hmis::Hud::Project'
      user.policy_for(record.organization, policy_type: :hmis_organization).can_create_project?
    when 'Hmis::Hud::Enrollment'
      project_policy = user.policy_for(record.project, policy_type: :hmis_project)
      form_role == :NEW_CLIENT_ENROLLMENT ? project_policy.can_create_and_enroll_new_clients? : project_policy.can_enroll_clients?
    when *PROJECT_RELATED_CLASSES
      user.policy_for(record.project, policy_type: :hmis_project).can_edit?
    when 'Hmis::Hud::Service', 'Hmis::Hud::CustomService'
      user.policy_for(record.enrollment, policy_type: :hmis_enrollment).can_edit?
    when *ENROLLMENT_RELATED_CLASSES
      user.policy_for(record.enrollment, policy_type: :hmis_enrollment).can_edit?
    when 'HmisExternalApis::AcHmis::ReferralPosting'
      source_project = record.referral.enrollment.project
      user.policy_for(source_project, policy_type: :hmis_project).can_send_out_direct_referral?
    when 'Hmis::File'
      Hmis::File.authorize_proc.call(record.client, user)
    else
      raise "No authorization configured for #{record.class.name}"
    end
  end

  def authorized_to_edit?(record)
    raise 'expected record to be an existing record' unless record.persisted?
    # raise if trying to edit form role that should only be used for new record creation. FIXME: should be configured somewhere?
    raise 'Edit not supported for NEW_CLIENT_ENROLLMENT form role' if form_role == :NEW_CLIENT_ENROLLMENT

    case record.class.name
    when 'Hmis::Hud::Client'
      user.policy_for(record, policy_type: :hmis_client).can_edit?
    when 'Hmis::Hud::Organization'
      user.policy_for(record, policy_type: :hmis_organization).can_edit?
    when 'Hmis::Hud::Project'
      user.policy_for(record, policy_type: :hmis_project).can_edit?
    when 'Hmis::Hud::Enrollment'
      user.policy_for(record, policy_type: :hmis_enrollment).can_edit?
    when *PROJECT_RELATED_CLASSES
      user.policy_for(record.project, policy_type: :hmis_project).can_edit?
    when 'Hmis::Hud::Service', 'Hmis::Hud::CustomService'
      user.policy_for(record.enrollment, policy_type: :hmis_enrollment).can_edit?
    when *ENROLLMENT_RELATED_CLASSES
      user.policy_for(record.enrollment, policy_type: :hmis_enrollment).can_edit?
    when 'HmisExternalApis::AcHmis::ReferralPosting'
      source_project = record.referral.enrollment.project
      user.policy_for(source_project, policy_type: :hmis_project).can_send_out_direct_referral?
    when 'Hmis::File'
      Hmis::File.authorize_proc.call(record, user)
    else
      raise "No authorization configured for #{record.class.name}"
    end
  end
end
