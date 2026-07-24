###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse
  class DashboardExportFile < GrdaWarehouse::File
    mount_uploader :file, FileUploader # Tells rails to use this uploader for this model.

    has_one_attached :dashboard_export_file, dependent: false

    def file_data
      return dashboard_export_file.download if dashboard_export_file.attached?

      content
    end

    scope :unprocessed_s3_migration, -> do
      migrated = ActiveStorage::Attachment.where(record_type: 'GrdaWarehouse::File', name: 'dashboard_export_file').pluck(:record_id)
      all = pluck(:id)
      unmigrated = all - migrated
      return none if unmigrated.blank?

      where(id: unmigrated)
    end

    def copy_to_s3!
      return unless content.present?
      return if dashboard_export_file.attached?

      Tempfile.create(binmode: true) do |tmp_file|
        tmp_file.write(content)
        tmp_file.rewind
        self.content = nil
        dashboard_export_file.attach(io: tmp_file, content_type: content_type, filename: read_attribute(:file).presence || 'export', identify: false)
        save!(validate: false)
      end
    end
  end
end
