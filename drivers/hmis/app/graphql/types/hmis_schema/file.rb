###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::File < Types::BaseObject
    description 'File'
    field :id, ID, null: false
    field :content_type, String, null: false
    field :enrollment_id, ID, null: true
    field :enrollment, Types::HmisSchema::Enrollment, null: true
    field :effective_date, GraphQL::Types::ISO8601Date, null: true
    field :expiration_date, GraphQL::Types::ISO8601Date, null: true
    field :confidential, Boolean, null: true
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_by, Types::Application::User, null: false
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
      return unless object.client_file.attached?
      # Use service url in dev to avoid CORS issues
      return object.client_file.blob.service_url if Rails.env.development?

      Rails.application.routes.url_helpers.rails_blob_url(object.client_file, only_path: true)
    end

    def tags
      object.tags.map(&:id)
    end

    def updated_by
      object.updated_by
    end

    def own_file
      object.user_id == current_user.id
    end
  end
end
