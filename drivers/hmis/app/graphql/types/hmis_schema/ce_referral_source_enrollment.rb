###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::CeReferralSourceEnrollment < Types::BaseObject
    # object is an OpenStruct with the following shape:
    # {
    #   enrollment: Hmis::Hud::Enrollment,
    #   definition_identifiers: [String],
    # }

    # Why definition_identifiers?
    # Often, a community will have a custom assessment that collects eligibility/prioritization info for CE.
    # We want to show the user, for example, "When was this enrollment's last Housing Needs Assessment"?
    # when they are looking at a list of candidate enrollments to choose for the referral's source enrollment.

    # Why not use Types::HmisSchema::Enrollment?
    # This type does NOT have object-level authorization. The user may be able to see possible source enrollments for
    # a referral, even without permission to see full enrollments in the project.

    field :id, ID, null: false

    field :project_name, String, null: false
    field :project_type, Types::HmisSchema::Enums::ProjectType, null: false

    field :entry_date, GraphQL::Types::ISO8601Date, null: false
    field :exit_date, GraphQL::Types::ISO8601Date, null: true
    field :in_progress, Boolean, null: false
    field :auto_exited, Boolean, null: false

    field :relationship_to_ho_h, HmisSchema::Enums::Hud::RelationshipToHoH, null: false, default_value: 99
    field :household_size, Integer, null: false
    field :other_household_member_names, [String], null: false

    field :assessments, [Types::HmisSchema::AssessmentNameWithDate], null: false

    def id
      object.enrollment.id
    end

    def project_name
      return Hmis::Hud::Project::CONFIDENTIAL_PROJECT_NAME if project.confidential && !current_permission?(permission: :can_view_enrollment_details, entity: object.enrollment)

      project.project_name
    end

    def project_type
      project.project_type
    end

    def entry_date
      object.enrollment.entry_date
    end

    def exit_date
      exit&.exit_date
    end

    def auto_exited
      exit&.auto_exited || false
    end

    def in_progress
      object.enrollment.in_progress?
    end

    def relationship_to_ho_h
      object.enrollment.relationship_to_ho_h
    end

    def household_size
      household_members.map(&:personal_id).uniq.size
    end

    def other_household_member_names
      household_members.filter do |enrollment|
        enrollment.id != object.enrollment.id
      end.map do |enrollment|
        current_permission?(permission: :can_view_client_name, entity: object.enrollment) ? enrollment.client.brief_name : enrollment.client.masked_name
      end
    end

    def assessments
      # Returns the most recent assessments relevant to the opportunity, grouped by form.
      # Even though definition_identifiers could refer to any form type,
      # we are hard-coding the assumption that only custom assessments will be used.

      # todo @martha - we want the most recent per type, but I'm stuck. resolve this in memory maybe
      object.enrollment.custom_assessments.not_in_progress.
        joins(:definition).
        where(definition: { identifier: object.definition_identifiers }).
        order(:date_updated).
        map do |assessment|
          OpenStruct.new(
            id: assessment.id,
            assessment_name: assessment.definition.title,
            date: assessment.assessment_date,
          )
        end
    end

    private

    def household_members
      household = load_ar_association(object.enrollment, :household)
      @household_members ||= load_ar_association(household, :enrollments)
    end

    def exit
      @exit ||= load_ar_association(object.enrollment, :exit)
    end

    def project
      @project ||= load_ar_association(object.enrollment, :project)
    end
  end
end
