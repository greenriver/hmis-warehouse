###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module TxClientReports
  class ResearchExports::Export < GrdaWarehouse::File
    mount_uploader :file, FileUploader
    belongs_to :user
    belongs_to :file, class_name: 'GrdaWarehouse::File', optional: true

    has_one_attached :research_export_file, dependent: false

    def file_data
      return research_export_file.download if research_export_file.attached?

      content
    end

    scope :unprocessed_s3_migration, -> do
      migrated = ActiveStorage::Attachment.where(record_type: 'GrdaWarehouse::File', name: 'research_export_file').pluck(:record_id)
      all = pluck(:id)
      unmigrated = all - migrated
      return none if unmigrated.blank?

      where(id: unmigrated)
    end

    def copy_to_s3!
      return unless content.present?
      return if research_export_file.attached?

      Tempfile.create(binmode: true) do |tmp_file|
        tmp_file.write(content)
        tmp_file.rewind
        self.content = nil
        research_export_file.attach(io: tmp_file, content_type: content_type, filename: read_attribute(:file).presence || 'research_export.xlsx', identify: false)
        save!(validate: false)
      end
    end
  end
end
