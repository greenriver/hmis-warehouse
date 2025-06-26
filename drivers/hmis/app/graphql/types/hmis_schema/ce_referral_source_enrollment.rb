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
    #   enrollment: Hmis::Hud::Enrollment, # MAY be an enrollment in a different data source than the current user!
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

    field :source_client_id, ID, null: false, description: 'The client id on the source enrollment, which is not necessarily in the current data source.'
    field :client_name, String, null: false, description: 'The name of the client on the source enrollment. Masked like "Client 123" if the user does not have permission to view the client name.'
    field :data_source, ::Types::Application::DataSource, null: false

    field :project_name, String, null: false
    field :project_type, Types::HmisSchema::Enums::ProjectType, null: false

    field :entry_date, GraphQL::Types::ISO8601Date, null: false
    field :exit_date, GraphQL::Types::ISO8601Date, null: true
    field :in_progress, Boolean, null: false
    field :auto_exited, Boolean, null: false

    field :relationship_to_ho_h, HmisSchema::Enums::Hud::RelationshipToHoH, null: false, default_value: 99
    field :household_size, Integer, null: false
    field :other_household_member_names, [String], null: false

    field :assessments, [Types::HmisSchema::AssessmentSummary], null: false

    def id
      object.enrollment.id
    end

    def source_client_id
      load_ar_association(object.enrollment, :client).id
    end

    def client_name
      # For now, we only resolve the name if the client is in the user's current data source. (Restricted by the permission check.)
      # In the future, we plan to add more nuanced permission checking against different data sources.
      client = load_ar_association(object.enrollment, :client)
      can_view_name = current_permission?(permission: :can_view_clients, entity: client) && current_permission?(permission: :can_view_client_name, entity: client)
      can_view_name ? client.brief_name : client.masked_name
    end

    def data_source
      load_ar_association(object.enrollment, :data_source)
    end

    def project_name
      project = load_ar_association(object.enrollment, :project)

      return Hmis::Hud::Project::CONFIDENTIAL_PROJECT_NAME if project.confidential && !current_permission?(permission: :can_view_enrollment_details, entity: object.enrollment)

      project.project_name
    end

    def project_type
      load_ar_association(object.enrollment, :project).project_type
    end

    def entry_date
      object.enrollment.entry_date
    end

    def exit_date
      load_ar_association(object.enrollment, :exit)&.exit_date
    end

    def auto_exited
      load_ar_association(object.enrollment, :exit)&.auto_exited || false
    end

    def in_progress
      object.enrollment.in_progress?
    end

    def relationship_to_ho_h
      object.enrollment.relationship_to_ho_h
    end

    def household_size
      household = load_ar_association(object.enrollment, :household)
      household_members = load_ar_association(household, :enrollments)
      household_members.map(&:personal_id).uniq.size
    end

    def other_household_member_names
      # Only resolve household member names if this user has permission to view full enrollment details.
      return [] unless can_view_enrollment_details

      household = load_ar_association(object.enrollment, :household)
      household_members = load_ar_association(household, :enrollments)

      household_members.filter do |enrollment|
        enrollment.id != object.enrollment.id
      end.map do |enrollment|
        current_permission?(permission: :can_view_client_name, entity: object.enrollment) ? enrollment.client.brief_name : enrollment.client.masked_name
      end
    end

    def assessments
      # Returns the most recent assessments relevant to the opportunity, grouped by form definition.
      # Even though definition_identifiers could refer to any form type, we are hard-coding the assumption that only custom assessments will be used.
      assessments = object.enrollment.custom_assessments.not_in_progress.
        joins(:definition).where(definition: { identifier: object.definition_identifiers })

      # We don't expect there to be a lot, so calculate in-memory the latest assessment per definition
      assessments.group_by(&:definition).map do |_, group|
        group.max_by { |assessment| [assessment.assessment_date, assessment.id] }
      end
    end

    private

    def can_view_enrollment_details
      current_permission?(permission: :can_view_enrollment_details, entity: object.enrollment)
    end
  end
end
