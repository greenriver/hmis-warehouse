###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module ClientFileBase
  extend ActiveSupport::Concern
  include ArelHelper
  include HasPiiAttributes

  included do
    pii_attr :note, as: :free_text
    pii_attr :name, as: :full_name
    pii_attr :client_file, as: :attached_file

    # dependent: false prevents soft-deletes (via acts_as_paranoid) from enqueuing
    # ActiveStorage::PurgeJob, which would delete the S3 blob while the DB record
    # is still restorable and may have pending AnalyzeJobs.
    # S3 blobs are cleaned up later by PurgeSoftDeletedClientFilesJob.
    # Use soft_delete/soft_delete! instead of .destroy (see below).
    has_one_attached :client_file, dependent: false

    # Use instead of .destroy to soft-delete without side effects.
    # acts_as_paranoid's .destroy runs :destroy callbacks, which triggers
    # acts_as_taggable's `dependent: :destroy` on the taggings association,
    # hard-deleting the join rows. That makes tag-based restore impossible.
    # S3 blobs are cleaned up later by PurgeSoftDeletedClientFilesJob.
    def soft_delete = update(deleted_at: Time.current)
    def soft_delete! = update!(deleted_at: Time.current)

    # The file_exists_and_not_too_large validation checks that the client_file exists, so we can rely on that and only validate presence of name if the file has a client_file attachment.
    # This avoids an awkward double-error "Name can't be blank" if the file is not uploaded or has expired.
    validates_presence_of :name, if: -> { client_file.attached? }
    validate :file_exists_and_not_too_large
    validate :note_if_other

    scope :newest_first, -> do
      order(created_at: :desc)
    end

    scope :non_cache, -> do
      where.not(name: 'Client Headshot Cache')
    end

    scope :client_photos, -> do
      # Query the taggings directly rather than via `tagged_with` so this matches the
      # headshot tag across File STI subclasses regardless of taggable_type.
      tag_id = ActsAsTaggableOn::Tag.where(
        name: headshot_tag_name,
      ).pluck(:id)
      tagging_ids = ActsAsTaggableOn::Tagging.where(tag_id: tag_id).
        pluck(:taggable_id)

      where(id: tagging_ids)
    end

    def self.headshot_tag_name
      'Client Headshot'
    end

    def tags
      GrdaWarehouse::AvailableFileTag.where(id: tag_list)
    end

    def file_exists_and_not_too_large
      errors.add :client_file, full_message: 'No uploaded file found.' if (client_file.byte_size || 0) < 100
      errors.add :client_file, full_message: 'File size should be less than 4 MB' if (client_file.byte_size || 0) > 4.megabytes
    end

    def note_if_other
      errors.add :note, 'Note is required if Other is chosen above' if tag_list.include?('Other') && note.blank?
    end

    def self.all_available_tags
      GrdaWarehouse::AvailableFileTag.all
    end

    def self.grouped_available_tags
      GrdaWarehouse::AvailableFileTag.grouped
    end

    def self.available_tags
      # To maintain default behavior for warehouse
      grouped_available_tags
    end

    def as_preview
      return client_file.download unless client_file.variable?

      begin
        client_file.variant(resize_to_limit: [1920, 1080]).processed.download
      rescue ActiveStorage::FileNotFoundError
        Rails.logger.warn('Could not find client file')
        return nil
      end
    end

    def as_thumb
      return nil unless client_file.variable?

      begin
        client_file.variant(resize_to_limit: [400, 400]).processed.download
      rescue ActiveStorage::FileNotFoundError
        Rails.logger.warn('Could not find client file')
        return nil
      end
    end
  end
end
