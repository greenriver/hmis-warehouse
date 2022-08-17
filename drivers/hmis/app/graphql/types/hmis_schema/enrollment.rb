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
    field :entry_date, GraphQL::Types::ISO8601DateTime, null: true
    field :exit_date, GraphQL::Types::ISO8601DateTime, null: true
    field :assessments, HmisSchema::Assessment.page_type, null: false
    field :events, HmisSchema::Event.page_type, null: false
    field :services, HmisSchema::Service.page_type, null: false
    # field :household, HmisSchema::Household, null: false

    def project
      load_ar_association(object, :project)
    end

    def exit_date
      exit&.exit_date
    end

    def exit
      load_ar_association(object, :exit)
    end

    # def household
    #   load_ar_association(object, :household)
    # end
  end
end
