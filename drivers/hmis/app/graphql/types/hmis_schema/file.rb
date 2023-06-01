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
    field :updated_by, Types::Application::User, null: true
    field :uploaded_by, Types::Application::User, null: true
    field :url, String, null: true
    field :name, String, null: false
    field :tags, [String], null: false
    field :file_blob_id, ID, null: true
    field :own_file, Boolean, null: false
    field :redacted, Boolean, null: false

    field :date_updated, GraphQL::Types::ISO8601DateTime, null: false
    field :date_created, GraphQL::Types::ISO8601DateTime, null: false
    hud_field :user, HmisSchema::User, null: true

    # Object is a Hmis::File

    def name
      unless_redacted('Confidential File') { object.name }
    end

    def redacted
      !!redacted?
    end

    def file_blob_id
      unless_redacted { object.client_file&.blob&.id }
    end

    def content_type
      object.client_file.content_type
    end

    def url
      unless_redacted do
        return unless object.client_file.attached?
        # Use service url in dev to avoid CORS issues
        return object.client_file.blob.service_url if Rails.env.development?

        Rails.application.routes.url_helpers.rails_blob_url(object.client_file, only_path: true)
      end
    end

    def tags
      unless_redacted([]) { object.tags.map(&:id) }
    end

    def date_created
      object.created_at
    end

    def date_updated
      object.updated_at
    end

    # HUD User that most recently touched the record, to match convention on HUD-like types
    def user
      unless_redacted do
        return unless object.user.present?

        user_last_touched = object.updated_by || object.user
        user_last_touched.hmis_data_source_id = current_user.hmis_data_source_id
        Hmis::Hud::User.from_user(user_last_touched)
      end
    end

    # Application user that uploaded the file
    def uploaded_by
      unless_redacted { object.user }
    end

    def updated_by
      unless_redacted { object.updated_by }
    end

    def own_file
      object.user_id == current_user.id
    end

    protected

    def unless_redacted(fallback = nil)
      return fallback if redacted?

      yield
    end

    def redacted?
      return false unless object.confidential
      return false if own_file && current_user.can_manage_own_client_files_for?(object)

      !current_user.can_view_any_confidential_client_files_for?(object)
    end
  end
end
