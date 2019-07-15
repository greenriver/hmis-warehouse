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

      @upload = Importers::HMISSixOneOne::UploadedZip.new(
        data_source_id: @data_source_id,
        upload_id: @import_log.upload_id,
      )

      self.logger = Rails.logger
      self.dry_run = dry_run
    end

    def run!
      logger.info "Removing import #{@import_id}"
      directory = reconstitute_import
      puts directory
      removed_data_notes = remove_imported_data(directory, @upload.export_id_addition)
      removed_data_notes.each do |msg|
        logger.info msg
      end
    end

    def export_id_extra


    end

    def export_id_addition
      @export_id_addition ||= @range.start.strftime('%Y%m%d')
    end

    def reconstitute_import
      @upload.import = @import_log
      file_path = @upload.reconstitute_upload
      @upload.expand(file_path: file_path)
      @upload.load_export_file
      @upload.range = @upload.set_date_range
      return ::File.dirname(file_path)
    end

    def remove_imported_data directory, export_id_addition
      removed_data_notes = []
      files = @upload.class.importable_files.map do |filename, klass|
        [::File.join(directory, filename), klass]
      end
      files.each do |path, klass|
        hud_keys = []
        hud_key = klass.hud_key
        export_id = nil
        CSV.foreach(path, headers: true) do |row|
          hud_keys << row[hud_key.to_s]
          export_id ||= @upload.set_useful_export_id(row: row, export_id: export_id_addition)['ExportID']
        end

        if klass.column_names.include?('DateDeleted')
          msg = "Attempting to remove #{hud_keys.count} #{klass.name}.  Data Source: #{@data_source_id}, ExportID #{export_id}..."
          logger.info msg
          removed_data_notes << msg
          removed = 0
          if dry_run
            hud_keys.each_slice(10_000) do |slice|
              removed += klass.where(
                data_source_id: @data_source_id,
                ExportID: export_id,
                hud_key => slice,
              ).count
            end
            msg = "Found #{removed} to remove."
            logger.info msg
            removed_data_notes << msg
          else
            # Mark all associated records as deleted, and update
            # the DateUpdated to be significantly in the past so that
            # any future restore will also force an update
            hud_keys.each_slice(10_000) do |slice|
              removed += klass.where(
                data_source_id: @data_source_id,
                ExportID: export_id,
                hud_key => slice,
              ).update_all(
                DateDeleted: Time.now,
                DateUpdated: '2000-01-01'
              )
            end
            msg = "Removed #{removed}."
            logger.info msg
            removed_data_notes << msg
          end
        end
      end
      return removed_data_notes
    end

  end
end
