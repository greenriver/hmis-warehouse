###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Assessment < Types::BaseObject
    description 'Custom Assessment'
    field :id, ID, null: false
    field :enrollment, HmisSchema::Enrollment, null: false
    field :assessment_date, GraphQL::Types::ISO8601Date, null: false
    field :data_collection_stage, HmisSchema::Enums::Hud::DataCollectionStage, null: true
    field :date_created, GraphQL::Types::ISO8601DateTime, null: false
    field :date_updated, GraphQL::Types::ISO8601DateTime, null: false
    field :date_deleted, GraphQL::Types::ISO8601DateTime, null: true
    field :custom_form, HmisSchema::CustomForm, null: true
    field :user, HmisSchema::User, null: true
    field :client, HmisSchema::Client, null: false
    field :in_progress, Boolean, null: false

    def in_progress
      object.in_progress?
    end

    def enrollment
      load_ar_association(object, :enrollment)
    end

    def custom_form
      load_ar_association(object, :custom_form)
    end

    def user
      load_ar_association(object, :user)
    end
  end
end
