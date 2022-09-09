###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enrollment < Types::BaseObject
    description 'HUD Enrollment'
    field :id, ID, null: false
    field :project, Types::HmisSchema::Project, null: false
    field :entry_date, GraphQL::Types::ISO8601Date, null: true
    field :exit_date, GraphQL::Types::ISO8601Date, null: true
    field :assessments, HmisSchema::Assessment.page_type, null: false
    field :events, HmisSchema::Event.page_type, null: false
    field :services, HmisSchema::Service.page_type, null: false
    field :household, HmisSchema::Household, null: false
    field :client, HmisSchema::Client, null: false
    field :in_progress, Boolean, null: false

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
  end
end
