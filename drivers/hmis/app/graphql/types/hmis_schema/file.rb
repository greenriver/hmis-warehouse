###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::File < Types::BaseObject
    description 'File'
    field :id, ID, null: false
    field :content_type, String, null: false
    field :effective_date, GraphQL::Types::ISO8601Date, null: true
    field :expiration_date, GraphQL::Types::ISO8601Date, null: true
    field :confidential, Boolean, null: true
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_by, Types::HmisSchema::User, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :url, String, null: false
    field :name, String, null: false
    field :tags, [String], null: false
    field :file_blob_id, ID, null: false
    field :own_file, Boolean, null: false

    # Object is a Hmis::File

    def file_blob_id
      object.client_file&.blob&.id
    end

    def content_type
      object.client_file.content_type
    end

    def url
      Rails.application.routes.url_helpers.rails_blob_url(object.client_file, host: ENV['FQDN']) if object.client_file.attached?
    end

    def tags
      object.tags.map(&:name)
    end

    def updated_by
      object.user
    end

    def own_file
      object.user.user_id == current_user.id.to_s
    end
  end
end
