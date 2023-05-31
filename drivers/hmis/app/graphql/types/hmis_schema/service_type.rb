###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::ServiceType < Types::BaseObject
    graphql_name 'ServiceType'
    field :id, ID, null: false
    field :name, String, null: false
    field :hud_record_type, HmisSchema::Enums::Hud::RecordType, null: true
    field :hud_type_provided, HmisSchema::Enums::ServiceTypeProvided, null: true
    field :category, String, null: false
    field :date_updated, GraphQL::Types::ISO8601DateTime, null: false
    field :date_created, GraphQL::Types::ISO8601DateTime, null: false
    field :user, HmisSchema::User, null: true

    def user
      load_ar_association(object, :user)
    end

    def category
      object.category.name
    end

    def type_provided
      [object.hud_record_type, object.hud_type_provided].compact_blank.join(':')
    end
  end
end
