###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse
  class NonHmisUpload < GrdaWarehouseBase
    include ActionView::Helpers::DateHelper
    acts_as_paranoid

    belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
    belongs_to :user, optional: true

    belongs_to :delayed_job, optional: true, class_name: '::Delayed::Job'

    mount_uploader :file, ImportUploader
    has_one_attached :upload_file, dependent: false

    # Returns the file bytes from ActiveStorage when migrated, else the legacy DB column.
    def file_data
      return upload_file.download if upload_file.attached?

      content
    end

    scope :unprocessed_s3_migration, -> do
      migrated = ActiveStorage::Attachment.where(record_type: 'GrdaWarehouse::NonHmisUpload', name: 'upload_file').pluck(:record_id)
      all = pluck(:id)
      unmigrated = all - migrated
      return none if unmigrated.blank?

      where(id: unmigrated)
    end

    def copy_to_s3!
      return unless content.present?
      return if upload_file.attached? # don't re-process

      Tempfile.create(binmode: true) do |tmp_file|
        tmp_file.write(content)
        tmp_file.rewind
        self.content = nil
        upload_file.attach(io: tmp_file, content_type: content_type, filename: read_attribute(:file).presence || 'upload', identify: false)
        save!(validate: false)
      end
    end

    validates :data_source, presence: true
    validate :file_attached, on: :create

    def status
      if percent_complete&.zero?
        'Queued'
      elsif percent_complete == 0.01
        'Started'
      elsif percent_complete == 100
        'Complete'
      else
        percent_complete
      end
    end

    def import_time(details: false)
      if delayed_job.present?
        return "Failed with: #{delayed_job.last_error.split("\n").first}" if delayed_job.last_error.present? && details
        return 'failed' if delayed_job.failed_at.present? || delayed_job.last_error.present?
      end
      if percent_complete == 100
        begin
          seconds = ((completed_at - created_at) / 1.minute).round * 60
          "#{distance_of_time_in_words(seconds)} -#{created_at.strftime('%l:%M %P')} to #{completed_at.strftime('%l:%M %P')}"
        rescue StandardError
          'unknown'
        end
      else
        'incomplete'
      end
    end

    private

    # New uploads store the file in ActiveStorage (`upload_file`); the legacy
    # CarrierWave `:file` mount is a read-only fallback that is no longer fed on
    # create, so its uploader is blank. Validate create-time presence against the
    # attachment instead.
    def file_attached
      errors.add(:file, :blank) unless upload_file.attached?
    end
  end
end
