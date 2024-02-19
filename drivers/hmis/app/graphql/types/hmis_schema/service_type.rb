###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::ServiceType < Types::BaseObject
    include Types::HmisSchema::HasHudMetadata

    graphql_name 'ServiceType'
    field :id, ID, null: false
    field :name, String, null: false
    field :hud, Boolean, null: false, method: :hud_service?
    field :hud_record_type, HmisSchema::Enums::Hud::RecordType, null: true
    field :hud_type_provided, HmisSchema::Enums::ServiceTypeProvided, null: true
    field :category, String, null: false

    # object is a Hmis::Hud::CustomServiceType

    def category
      object.category.name
    end

    def hud_type_provided
      return unless object.hud_service?

      [object.hud_record_type, object.hud_type_provided].join(':')
    end
  end
end
