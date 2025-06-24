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
    # }

    field :id, ID, null: false
    field :project_name, String, null: false
    field :relationship_to_ho_h, HmisSchema::Enums::Hud::RelationshipToHoH, null: false, default_value: 99
    field :entry_date, GraphQL::Types::ISO8601Date, null: false
    field :exit_date, GraphQL::Types::ISO8601Date, null: true
    field :in_progress, Boolean, null: false
    field :auto_exited, Boolean, null: false

    field :household_size, Integer, null: false
    field :other_household_member_names, [String], null: false

    def id
      object.enrollment.id
    end

    def relationship_to_ho_h
      object.enrollment.relationship_to_ho_h
    end

    def entry_date
      object.enrollment.entry_date
    end

    def project_name
      project = load_ar_association(object.enrollment, :project)

      return Hmis::Hud::Project::CONFIDENTIAL_PROJECT_NAME if project&.confidential && !current_permission?(permission: :can_view_enrollment_details, entity: object.enrollment)

      project&.project_name
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

    private

    def household_members
      household = load_ar_association(object.enrollment, :household)
      @household_members ||= load_ar_association(household, :enrollments)
    end

    def exit
      @exit ||= load_ar_association(object.enrollment, :exit)
    end
  end
end
