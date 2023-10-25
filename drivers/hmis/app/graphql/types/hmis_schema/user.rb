###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::User < Types::BaseObject
    description 'HUD User'
    field :id, ID, null: false
    field :hmis_id, ID, null: true
    field :name, String, null: false
    field :date_updated, GraphQL::Types::ISO8601DateTime, null: true
    field :date_created, GraphQL::Types::ISO8601DateTime, null: true
    field :date_deleted, GraphQL::Types::ISO8601DateTime, null: true

    available_filter_options do
      arg :search_term, String
    end

    def name
      [object.user_first_name, object.user_last_name].compact.join(' ')
    end

    def hmis_id
      return nil unless current_user.permissions?(:can_impersonate_users)

      # FIXME: this is probably not right
      email = object.user_email.downcase
      Hmis::User.active.not_system.where(email: object.user_email.downcase).first&.id if email
    end
  end
end
