###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse
  class ReportResultFile < GrdaWarehouse::File
    mount_uploader :file, FileUploader

    has_one_attached :report_result_file, dependent: false

    def file_data
      return report_result_file.download if report_result_file.attached?

      content
    end

    scope :unprocessed_s3_migration, -> do
      migrated = ActiveStorage::Attachment.where(record_type: 'GrdaWarehouse::File', name: 'report_result_file').pluck(:record_id)
      all = pluck(:id)
      unmigrated = all - migrated
      return none if unmigrated.blank?

      where(id: unmigrated)
    end

    def copy_to_s3!
      return unless content.present?
      return if report_result_file.attached?

      Tempfile.create(binmode: true) do |tmp_file|
        tmp_file.write(content)
        tmp_file.rewind
        self.content = nil
        report_result_file.attach(io: tmp_file, content_type: content_type, filename: read_attribute(:file).presence || 'result', identify: false)
        save!(validate: false)
      end
    end

    def save_zip_to(path)
      reconstitute_path = ::File.join(path, 'report_result.zip')
      FileUtils.mkdir_p(path) unless ::File.directory?(path)
      ::File.open(reconstitute_path, 'w+b') do |file|
        file.write(file_data)
      end
      reconstitute_path
    end
  end
end
