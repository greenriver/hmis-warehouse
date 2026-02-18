###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Builds a new (unpersisted) record for the given class, initialized with associations
# derived from the form submission input.
class Hmis::Form::RecordBuilder
  def initialize(klass:, input:, user:)
    @klass = klass
    @input = input
    @user = user
    @data_source_id = user.hmis_data_source_id
  end

  def build
    project = Hmis::Hud::Project.viewable_by(@user).find_by(id: @input.project_id) if @input.project_id.present?
    client = Hmis::Hud::Client.viewable_by(@user).find_by(id: @input.client_id) if @input.client_id.present?
    enrollment = Hmis::Hud::Enrollment.viewable_by(@user).find_by(id: @input.enrollment_id) if @input.enrollment_id.present?
    organization = Hmis::Hud::Organization.viewable_by(@user).find_by(id: @input.organization_id) if @input.organization_id.present?
    custom_service_type = Hmis::Hud::CustomServiceType.find_by(id: @input.service_type_id) if @input.service_type_id.present?

    ds = { data_source_id: @data_source_id }

    case @klass.name
    when 'Hmis::Hud::Client'
      @klass.new(ds)
    when 'Hmis::Hud::Organization'
      @klass.new(ds)
    when 'Hmis::Hud::Project'
      @klass.new(
        {
          **ds,
          organization_id: organization&.organization_id,
          # Generate project ID upfront so that related records created via nested attributes will be valid
          project_id: @klass.generate_uuid,
        },
      )
    when 'Hmis::Hud::Funder', 'Hmis::Hud::ProjectCoc', 'Hmis::Hud::Inventory', 'Hmis::Hud::CeParticipation', 'Hmis::Hud::HmisParticipation'
      @klass.new({ project_id: project&.project_id, **ds })
    when 'Hmis::Hud::Enrollment'
      @klass.new({ project_id: project&.project_id, project_pk: project&.id, personal_id: client&.personal_id, **ds })
    when 'Hmis::Hud::CurrentLivingSituation'
      @klass.new({ personal_id: enrollment&.personal_id, enrollment_id: enrollment&.enrollment_id, **ds })
    when 'Hmis::Hud::HmisService'
      raise 'cannot create service without custom service type' unless custom_service_type.present?

      attrs = { enrollment_id: enrollment&.EnrollmentID, personal_id: enrollment&.PersonalID, **ds }
      if custom_service_type.hud_service?
        Hmis::Hud::Service.new(record_type: custom_service_type.hud_record_type, type_provided: custom_service_type.hud_type_provided, **attrs)
      else
        Hmis::Hud::CustomService.new(custom_service_type: custom_service_type, **attrs)
      end
    when 'HmisExternalApis::AcHmis::ReferralRequest'
      # DEPRECATED: ReferralRequest creation is no longer supported via form submission.
      raise 'ReferralRequest form submission is no longer supported'
    when 'HmisExternalApis::AcHmis::ReferralPosting'
      # Look up the receiving project without `viewable_by` scope, since referrer may not have access to receiving project
      receiving_project = Hmis::Hud::Project.find_by(id: @input.project_id)
      raise HmisErrors::ApiError, 'Access denied' unless enrollment.present? && receiving_project.present?

      HmisExternalApis::AcHmis::ReferralPosting.new_with_referral(
        enrollment: enrollment, # enrollment at the source project
        receiving_project: receiving_project,
        user: @user,
      )
    when 'Hmis::File'
      @klass.new({ client_id: client&.id, enrollment_id: enrollment&.id })
    when 'Hmis::Hud::Assessment', 'Hmis::Hud::CustomCaseNote', 'Hmis::Hud::Event'
      @klass.new({ personal_id: enrollment&.personal_id, enrollment_id: enrollment&.enrollment_id, **ds })
    else
      raise "No record builder specified for #{@klass.name}"
    end
  end
end
