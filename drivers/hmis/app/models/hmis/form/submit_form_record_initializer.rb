###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Builds an unsaved record for form submission (create path). Resolves associations from input
# using user (viewable_by). Used by SubmitForm mutation before authorizing create.
#
# Args:
# - owner_class: the class of the record to build
# - input: the input from the form submission (Types::HmisSchema::FormInput) this contains IDs for related records
# - user: the user submitting the form (Hmis::User)
class Hmis::Form::SubmitFormRecordInitializer
  ENROLLMENT_RELATED_CLASSES = [
    'Hmis::Hud::CurrentLivingSituation',
    'Hmis::Hud::Assessment',
    'Hmis::Hud::CustomCaseNote',
    'Hmis::Hud::Event',
  ].freeze

  PROJECT_RELATED_CLASSES = [
    'Hmis::Hud::Funder',
    'Hmis::Hud::ProjectCoc',
    'Hmis::Hud::Inventory',
    'Hmis::Hud::CeParticipation',
    'Hmis::Hud::HmisParticipation',
  ].freeze

  def self.build(owner_class:, input:, user:)
    new(owner_class: owner_class, user: user).build(input)
  end

  def initialize(owner_class:, user:)
    @owner_class = owner_class
    @user = user
  end

  def build(input)
    raise 'shouldn\'t be called for input with record_id' if input.record_id.present?

    associations = resolve_associations(input)
    build_record(associations)
  end

  private

  attr_reader :owner_class, :user

  def resolve_associations(input)
    # skip viewable_by check for ReferralPosting (legacy) because sender doesn't need to have access to receiving project
    dangerous_skip_project_viewability = owner_class.name == 'HmisExternalApis::AcHmis::ReferralPosting'
    {
      project: dangerous_skip_project_viewability ? Hmis::Hud::Project.find(input.project_id) : find_viewable(Hmis::Hud::Project, input.project_id),
      client: find_viewable(Hmis::Hud::Client, input.client_id),
      enrollment: find_viewable(Hmis::Hud::Enrollment, input.enrollment_id),
      organization: find_viewable(Hmis::Hud::Organization, input.organization_id),
      custom_service_type: input.service_type_id.present? ? Hmis::Hud::CustomServiceType.find_by(id: input.service_type_id) : nil,
    }
  end

  def find_viewable(scope, id)
    return nil if id.blank?

    found = scope.viewable_by(user).find_by(id: id)
    raise "User not authorized to view associated record #{scope.name}##{id} (record not found)" unless found

    found
  end

  def ds
    { data_source_id: user.hmis_data_source_id }
  end

  def build_record(associations)
    case owner_class.name
    when 'Hmis::Hud::Client'
      build_client_record(associations)
    when 'Hmis::Hud::Organization'
      build_organization_record(associations)
    when 'Hmis::Hud::Project'
      build_project_record(associations)
    when 'Hmis::Hud::Enrollment'
      build_enrollment_record(associations)
    when *PROJECT_RELATED_CLASSES
      build_project_related_record(associations)
    when 'Hmis::Hud::HmisService'
      build_hmis_service_record(associations)
    when *ENROLLMENT_RELATED_CLASSES
      build_enrollment_related_record(associations)
    when 'HmisExternalApis::AcHmis::ReferralRequest'
      raise 'ReferralRequest form submission is no longer supported'
    when 'HmisExternalApis::AcHmis::ReferralPosting'
      build_referral_posting_record(associations)
    when 'Hmis::File'
      build_file_record(associations)
    else
      raise "No initialization configured for #{owner_class.name}"
    end
  end

  def build_client_record(_associations)
    Hmis::Hud::Client.new(ds)
  end

  def build_organization_record(_associations)
    Hmis::Hud::Organization.new(ds)
  end

  def build_project_record(associations)
    organization = associations[:organization]
    raise 'cannot create project-related record without organization' unless organization

    Hmis::Hud::Project.new(
      **ds,
      organization_id: organization.organization_id,
      project_id: Hmis::Hud::Base.generate_uuid,
    )
  end

  def build_enrollment_record(associations)
    project = associations[:project]
    client = associations[:client]
    raise 'cannot create enrollment without project' unless project

    Hmis::Hud::Enrollment.new(
      project_id: project.project_id,
      project_pk: project.id,
      personal_id: client&.personal_id, # note: client is not present for 'new client enrollment' form submission because they don't exist yet
      **ds,
    )
  end

  def build_project_related_record(associations)
    project = associations[:project]
    raise 'cannot create project related record without project' unless project

    owner_class.new(project_id: project.project_id, **ds)
  end

  def build_hmis_service_record(associations)
    custom_service_type = associations[:custom_service_type]
    enrollment = associations[:enrollment]
    raise 'cannot create service without custom service type' unless custom_service_type
    raise 'cannot create service without enrollment' unless enrollment

    attrs = { enrollment_id: enrollment.enrollment_id, personal_id: enrollment.personal_id, **ds }
    if custom_service_type.hud_service?
      Hmis::Hud::Service.new(
        record_type: custom_service_type.hud_record_type,
        type_provided: custom_service_type.hud_type_provided,
        **attrs,
      )
    else
      Hmis::Hud::CustomService.new(custom_service_type: custom_service_type, **attrs)
    end
  end

  def build_enrollment_related_record(associations)
    enrollment = associations[:enrollment]
    raise 'cannot create enrollment without enrollment' unless enrollment

    owner_class.new(
      personal_id: enrollment.personal_id,
      enrollment_id: enrollment.enrollment_id,
      **ds,
    )
  end

  def build_referral_posting_record(associations)
    HmisExternalApis::AcHmis::ReferralPosting.new_with_referral(
      enrollment: associations[:enrollment],
      receiving_project: associations[:project],
      user: user,
    )
  end

  def build_file_record(associations)
    client = associations[:client]
    raise 'cannot create file without client' unless client

    Hmis::File.new(
      client_id: client.id,
      enrollment_id: associations[:enrollment]&.id,
    )
  end
end
