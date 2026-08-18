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

    has_one_attached :upload_file, dependent: false

    # Returns the file bytes from ActiveStorage when migrated, else the legacy DB column.
    def file_data
      return upload_file.download if upload_file.attached?

      content
    end

    def filename
      return upload_file.filename.to_s if upload_file.attached?

      self[:file].to_s
    end

    # A client-supplied MIME type can be spoofed. ActiveStorage derives the blob's content type from the actual bytes.
    def detected_content_type
      return content_type unless upload_file.attached?

      upload_file.blob&.content_type || content_type
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

    # New uploads store the file in ActiveStorage (`upload_file`); ensure the attachment
    # is present before creating a new record.
    def file_attached
      errors.add(:file, :blank) unless upload_file.attached?
    end
  end
end
