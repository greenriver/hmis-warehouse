###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::ProjectCoc < Types::BaseObject
    description 'HUD Project CoC'
    field :id, ID, null: false
    field :project, Types::HmisSchema::Project, null: false
    field :coc_code, String, null: false
    field :geocode, String, null: false
    field :address1, String, null: true
    field :address2, String, null: true
    field :city, String, null: true
    field :state, String, null: true
    field :zip, String, null: true
    field :geography_type, HmisSchema::Enums::GeographyType, null: true
    field :date_created, GraphQL::Types::ISO8601DateTime, null: false
    field :date_updated, GraphQL::Types::ISO8601DateTime, null: false
    field :date_deleted, GraphQL::Types::ISO8601DateTime, null: true
    # field :user, HmisSchema::User, null: false

    # TODO: Add user type
    # def user
    #   load_ar_association(object, :user)
    # end
  end
end
