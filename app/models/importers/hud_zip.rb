
require 'zip'
require 'csv'
module Importers
  class HudZip
    EXTRACT_DIRECTORY = 'tmp/hud_zip'
    def initialize import_id
      unless import_id.present?
        puts "Import ID is required, try: "
        puts "rake data_lake:import_hud_zip[2]"
        return
      end
      @import = Import.find(import_id.to_i)
    end
    def run!
      return unless @import.present?
      Rails.logger.info "Extracting: #{@import.file.current_path}"
      unzip
      load
      if @import.percent_complete == 100
        @import.update_attribute(:completed_at, Time.now)
        remove_files
      end
    end

    private def unzip
      return unless File.exist?(@import.file.current_path)
      begin
        unzipped_files = []
        Zip::File.open(@import.file.current_path) do |zip_file|
          zip_file.each do |entry|
            unzip_path = extract_path(entry)
            unzip_parent = File.dirname(unzip_path)
            unless File.directory?(unzip_parent)
              FileUtils.mkdir_p(unzip_parent)
            end
            entry.extract(extract_path entry)
            unzipped_files << [klass_name(entry), extract_path(entry)] if entry.name.include?('.csv')
          end
        end
      rescue StandardError => ex
        Rails.logger.error ex.message
        raise "Unable to extract file: #{@import.file.current_path}"
      end
      # If the file was extracted successfully, delete the source file
      File.delete(@import.file.current_path) if File.exist?(@import.file.current_path)
      @import.percent_complete = 0.01
      @import.unzipped_files = unzipped_files
      @import.import_errors = []
      @import.save
    end

    # loop over each entry in unzipped_files, attempt to load them into tables with the
    # same names as the files.
    # Every record should be appended with the import_id column (id of @import)
    private def load
      return unless @import.unzipped_files.present?
      DataLake::Hud::Base.transaction do
        files = @import.unzipped_files.to_h
        # Always import the export table first since we have foreign keys
        # Also, sometimes the Export file has an extry column (HashStatus), which we need to remove
        import "DataLake::Hud::Export", files["DataLake::Hud::Export"]
        files.delete("DataLake::Hud::Export")
        processed = 1
        files.each do |klass, file_path|
          import klass, file_path
          @import.update_attribute(:percent_complete, (processed.to_f / files.size * 100))
          processed += 1
        end
      end
    end

    private def extract_path entry
      "#{EXTRACT_DIRECTORY}#{@import.file.url.gsub('/tmp/uploads/import','').gsub(@import.file_identifier, '').gsub(Rails.root.to_s, '')}#{entry.name}"
    end

    private def klass_name entry
      hud_classes = {
        'EnrollmentCoC' => 'DataLake::Hud::EnrollmentCoc',
        'HealthAndDV' => 'DataLake::Hud::HealthAndDv',
        'ProjectCoC' => 'DataLake::Hud::ProjectCoc',
      }
      if hud_classes[entry.name.split('/')[-1].gsub('.csv', '')].present?
        hud_classes[entry.name.split('/')[-1].gsub('.csv', '')]
      else
        "DataLake::Hud::#{entry.name.split('/')[-1].gsub('.csv', '').singularize}"
      end
    end

    private def import klass, file_path
      header_row = true
      rows = []
      headers = []
      Rails.logger.info "Processing: #{file_path}"
      # cleanup messy export files
      if file_path.include? 'Export.csv'
        export_table = CSV.read(file_path, headers: true)
        export_table.delete('HashStatus')
        CSV.open(file_path, "w") do |csv|
          csv << export_table.headers
          export_table.each do |line|
            csv << line
          end
        end
      end
      # Disable logging so we don't fill the disk
      ActiveRecord::Base.logger.silence do
        File.foreach(file_path) do |line|
          begin
            CSV.parse(line) do |row|
              if header_row
                header_row = false
                headers = row
                headers << :import_id
                next
              end
              if row.any?
                row << @import.id
                klass.constantize.import headers, [row]
              end
            end
          #rescue CSV::MalformedCSVError => e
          # FIXME: clean this up
          rescue Exception => e
            @import.import_errors << {
               text: "Error on line #{$.} of #{File.basename(file_path)}",
               message: e.message,
               line: line,
            }
            @import.save
            next
          end
        end
      end
    end

    private def remove_files
      return unless @import.unzipped_files.present?
      Rails.logger.info "Deleting: #{@import.unzipped_files.to_h.values.join(', ')}"
      @import.unzipped_files.to_h.values.each{|m| File.delete("#{Rails.root}/#{m}")}
    end

  end
end