###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::File < Types::BaseObject
    # Object is a Hmis::File
    description 'File'
    field :id, ID, null: false
    field :content_type, String, null: true
    field :enrollment_id, ID, null: true
    field :enrollment, Types::HmisSchema::Enrollment, null: true
    field :effective_date, GraphQL::Types::ISO8601Date, null: true
    field :expiration_date, GraphQL::Types::ISO8601Date, null: true
    field :confidential, Boolean, null: true
    field :updated_by, Types::Application::User, null: true
    field :uploaded_by, Types::Application::User, null: true
    field :url, String, null: true
    field :name, String, null: false
    field :note, String, null: true
    field :tags, [String], null: false
    field :own_file, Boolean, null: false
    field :redacted, Boolean, null: false

    field :date_updated, GraphQL::Types::ISO8601DateTime, null: true
    field :date_created, GraphQL::Types::ISO8601DateTime, null: true
    hud_field :user, Application::User, null: true

    access_field do
      define_method(:policy) { @policy ||= policy_for(object, policy_type: :hmis_file) }

      bool_field(:can_edit_file) { policy.can_edit? }
      bool_field(:can_delete_file) { policy.can_delete? }
    end

    def name
      unless_redacted('Confidential File') { object.name || "File #{object.id}" }
    end

    def note
      unless_redacted { object.note }
    end

    def redacted
      !!redacted?
    end

    # Users with can_manage_own_client_files can see their own files on enrollments they can't view.
    # Resolve null in that case; an unauthorized Enrollment object would fail the whole query.
    def enrollment
      enrollment = load_ar_association(object, :enrollment)
      return unless enrollment
      return unless Types::HmisSchema::Enrollment.authorized?(enrollment, context)

      enrollment
    end

    def file_blob_id
      unless_redacted { client_file_blob&.id }
    end

    def content_type
      client_file_blob&.content_type
    end

    def url
      unless_redacted do
        return unless client_file_attachment.present?

        Rails.application.routes.url_helpers.hmis_client_file_path(client_id: object.client_id, id: object.id)
      end
    end

    # Log url access only when a non-nil value was actually resolved
    def activity_log_field_name(field_name, value = nil)
      case field_name
      when 'url'
        value.present? ? 'url' : nil
      end
    end

    def tags
      unless_redacted([]) do
        # Equivalent to ClientFileBase#tags, which queries per file; batch-load through the taggings instead
        taggings = load_ar_association(object, :tag_taggings).select { |tagging| tagging.tagger_id.nil? }
        tag_names = dataloader.with(Sources::ActiveRecordAssociation, :tag).load_all(taggings).compact.map(&:name)
        dataloader.with(Sources::ActiveRecordScope, GrdaWarehouse::AvailableFileTag).load_all(tag_names).compact.map(&:id)
      end
    end

    def date_created
      object.created_at
    end

    def date_updated
      object.updated_at
    end

    # User that most recently touched the record, to match convention on HUD-like types
    def user
      return if redacted?

      updated_by_user || uploaded_by_user
    end

    # Application user that uploaded the file
    def uploaded_by
      unless_redacted { uploaded_by_user }
    end

    def updated_by
      unless_redacted { updated_by_user }
    end

    def own_file
      object.user_id == current_user.id
    end

    protected

    def client_file_attachment
      load_ar_association(object, :client_file_attachment)
    end

    def client_file_blob
      attachment = client_file_attachment
      load_ar_association(attachment, :blob) if attachment
    end

    def uploaded_by_user
      load_ar_association(object, :user)
    end

    def updated_by_user
      load_ar_association(object, :updated_by)
    end

    def unless_redacted(fallback = nil)
      return fallback if redacted?

      yield
    end

    def redacted?
      !current_user.policy_for(object, policy_type: :hmis_file).can_view_unredacted?
    end
  end
end
