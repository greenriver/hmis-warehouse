###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  module HmisSchema
    module HasHudMetadata
      extend ActiveSupport::Concern

      included do
        # HUD User that most recently touched the record
        field(:user, HmisSchema::User, null: true) {}

        # Note: while these are required in the HUD spec, they are not (yet) required
        # by the database schema. If/when they become required in the db for all hud tables,
        # this can be updated to 'null: false'
        field(:date_updated, GraphQL::Types::ISO8601DateTime, null: true) {}
        field(:date_created, GraphQL::Types::ISO8601DateTime, null: true) {}
        # # Note: we don't currently resolve deleted records ever, but we may in the future.
        field(:date_deleted, GraphQL::Types::ISO8601DateTime, null: true) {}

        define_method(:user) do
          load_ar_association(object, :user)
        end
      end
    end
  end
end
