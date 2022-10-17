###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enrollment < Types::BaseObject
    include Types::HmisSchema::HasEvents
    include Types::HmisSchema::HasServices
    include Types::HmisSchema::HasAssessments

    description 'HUD Enrollment'
    field :id, ID, null: false
    field :project, Types::HmisSchema::Project, null: false
    field :entry_date, GraphQL::Types::ISO8601Date, null: true
    field :exit_date, GraphQL::Types::ISO8601Date, null: true
    assessments_field :assessments, type: HmisSchema::Assessment.page_type, null: false
    events_field :events, type: HmisSchema::Event.page_type, null: false
    services_field :services, type: HmisSchema::Service.page_type, null: false
    field :household, HmisSchema::Household, null: false
    field :client, HmisSchema::Client, null: false
    field :relationship_to_ho_h, HmisSchema::Enums::RelationshipToHoH, null: false
    field :in_progress, Boolean, null: false
    field :date_updated, GraphQL::Types::ISO8601DateTime, null: true
    field :date_created, GraphQL::Types::ISO8601DateTime, null: true

    def project
      load_ar_association(object.in_progress? ? object.wip : object, :project)
    end

    def exit_date
      exit&.exit_date
    end

    def exit
      load_ar_association(object, :exit)
    end

    def household
      return nil unless object.household_id.present?

      Hmis::Hud::Enrollment.where(household_id: object.household_id).preload(:client)
    end

    def in_progress
      object.in_progress?
    end

    def events(**args)
      resolve_events(**args)
    end

    def services(**args)
      resolve_services(**args)
    end

    def assessments(**args)
      resolve_assessments(**args)
    end
  end
end
