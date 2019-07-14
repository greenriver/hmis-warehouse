###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse
  class ImportRemover

    attr_accessor :logger, :dry_run
    def initialize import_id, dry_run: false
      @import_log = GrdaWarehouse::ImportLog.find(import_id)
      # we don't have a zip file path when everything is done, reset it
      path = 'import_remover'
      @import_log.update(zip: @import_log.upload.file.to_s)

      @data_source_id = @import_log.data_source_id
      self.logger = Rails.logger
      self.dry_run = dry_run
    end

    def run!
      logger.info "Removing import #{@import_id}"
      file_locations = reconstitute_import
      remove_imported_data(file_locations)
    end

    def reconstitute_import
      upload = Importers::UploadedZip.new(upload_id: @import_log.upload_id)
      upload.import = @import_log
      upload.unzip
    end

    def remove_imported_data files
      files.each do |class_name, path|
        klass = class_name.constantize
        hud_keys = []
        hud_key = klass.hud_key
        export_id = nil
        CSV.foreach(path, headers: true) do |row|
          hud_keys << row[hud_key.to_s]
          export_id ||= row['ExportID']
        end

        if klass.column_names.include?('DateDeleted')
          logger.info "Attempting to remove #{hud_keys.count} #{class_name}.  Data Source: #{@data_source_id}, ExportID #{export_id}..."
          removed = 0
          if dry_run
            hud_keys.each_slice(10_000) do |slice|
              removed += klass.where(
                data_source_id: @data_source_id,
                ExportID: export_id,
                hud_key => slice,
              ).count
            end
            logger.info "Found #{removed} to remove."
          else
            hud_keys.each_slice(10_000) do |slice|
              removed += klass.where(
                data_source_id: @data_source_id,
                ExportID: export_id,
                hud_key => slice,
              ).update_all(DateDeleted: Time.now)
            end
            logger.info "Removed #{removed}."
          end

        end
      end
    end

  end
end
