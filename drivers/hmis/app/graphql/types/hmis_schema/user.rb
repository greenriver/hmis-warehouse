###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::User < Types::BaseObject
    # maps to Hmis::Hud::User
    description 'HUD User'
    field :id, ID, null: false
    field :name, String, null: false
    field :date_updated, GraphQL::Types::ISO8601DateTime, null: true
    field :date_created, GraphQL::Types::ISO8601DateTime, null: true
    field :date_deleted, GraphQL::Types::ISO8601DateTime, null: true

    def name
      [object.user_first_name, object.user_last_name].compact.join(' ')
    end
  end
end
