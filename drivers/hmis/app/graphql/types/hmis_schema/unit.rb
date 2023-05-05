###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Unit < Types::BaseObject
    field :id, ID, null: false
    field :name, String, null: true
    field :start_date, GraphQL::Types::ISO8601Date, null: false
    field :end_date, GraphQL::Types::ISO8601Date, null: true
    field :unit_type, Types::HmisSchema::UnitTypeObject, null: true
    field :project, Types::HmisSchema::Project, null: true
    field :date_updated, GraphQL::Types::ISO8601DateTime, null: false
    field :date_created, GraphQL::Types::ISO8601DateTime, null: false
    field :user, HmisSchema::User, null: false
    field :unit_size, Integer, null: true

    def user
      user = object.user
      user.hmis_data_source_id = current_user.hmis_data_source_id
      Hmis::Hud::User.from_user(user)
    end

    def unit_size
      return object.unit_size if object.unit_size.present?

      object.unit_type&.unit_size
    end
  end
end
