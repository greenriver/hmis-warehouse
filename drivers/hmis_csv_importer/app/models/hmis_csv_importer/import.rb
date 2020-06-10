###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

# Assumptions:
# The import is authoritative for the date range specified in the Export.csv file
# The import is authoritative for the projects specified in the Project.csv file
# There's no reason to have client records with no enrollments
# All tables that hang off a client also hang off enrollments
module HmisCsvImporter
  class Import
    def set_date_range
      Filters::DateRange.new(start: @export.ExportStartDate.to_date, end: @export.ExportEndDate.to_date)
    end

    def set_involved_projects
      # FIXME
      # project_source.load_from_csv(
      #   file_path: @file_path,
      #   data_source_id: @data_source.id
      # )
    end

    def already_running_for_data_source?
      running = GrdaWarehouse::DataSource.advisory_lock_exists?("hud_import_#{@data_source.id}")
      logger.warn "Import of Data Source: #{@data_source.short_name} already running...exiting" if running
      running
    end

    def self.pre_calculate_source_hashes!
      importable_files.each do |_, klass|
        klass.pre_calculate_source_hashes!
      end
    end

    def complete_import
      @data_source.update(last_imported_at: Time.zone.now)
      @import.completed_at = Time.zone.now
      @import.upload_id = @upload.id if @upload.present?
      @import.save
    end

    def import_class(klass)
      # FIXME
      log("Importing #{klass.name}")
      begin
        file = importable_files.key(klass)
        return unless @import.summary[file].present?

        stats = klass.import_related!(
          data_source_id: @data_source.id,
          file_path: @file_path,
          stats: @import.summary[file],
          soft_delete_time: @soft_delete_time,
        )
        errors = stats.delete(:errors)
        setup_summary(klass.file_name)
        @import.summary[klass.file_name].merge!(stats)
        if errors.present?
          errors.each do |error|
            add_error(file_path: klass.file_name, message: error[:message], line: error[:line])
          end
        end
      rescue ActiveRecord::ActiveRecordError => e
        message = "Unable to import #{klass.name}: #{e.message}"
        add_error(file_path: klass.file_name, message: message, line: '')
      end
    end

    def mark_upload_complete
      @upload.update(percent_complete: 100, completed_at: @import.completed_at)
    end

    def self.export_source
      GrdaWarehouse::Import::HmisTwentyTwenty::Export
    end

    def export_source
      self.class.export_source
    end
  end
end
