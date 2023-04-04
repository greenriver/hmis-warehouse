###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Disability < Types::BaseObject
    def self.configuration
      Hmis::Hud::Disability.hmis_configuration(version: '2022')
    end

    field :id, ID, null: false
    field :enrollment, HmisSchema::Enrollment, null: false
    field :client, HmisSchema::Client, null: false
    field :user, HmisSchema::User, null: true
    hud_field :information_date
    hud_field :disability_type, HmisSchema::Enums::Hud::DisabilityType
    hud_field :disability_response, HmisSchema::Enums::Hud::DisabilityResponse
    hud_field :indefinite_and_impairs
    hud_field :data_collection_stage, HmisSchema::Enums::Hud::DataCollectionStage, null: false
    hud_field :date_updated
    hud_field :date_created
    hud_field :date_deleted

    # TODO ADD: source assessment

    def enrollment
      load_ar_association(object, :enrollment)
    end

    def client
      load_ar_association(object, :client)
    end

    def user
      load_ar_association(object, :user)
    end
  end
end
