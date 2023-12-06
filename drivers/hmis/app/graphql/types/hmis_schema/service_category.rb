###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::ServiceCategory < Types::BaseObject
    include Types::HmisSchema::HasHudMetadata

    graphql_name 'ServiceCategory'
    field :id, ID, null: false
    field :name, String, null: false
    # field :service_types, HmisSchema::ServiceType.page_type, null: false

    # object is a Hmis::Hud::CustomServiceCategory
  end
end
