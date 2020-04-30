###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

require 'zip'
module HudReports
  class ZipExporter
    def initialize(report, file_path: 'var/hud_report')
      @report = report
      @file_path = "#{file_path}/#{Process.pid}" # Usual Unixism -- create a unique path based on the PID
    end

    def export!
      create_export_directory
      begin
        @report.question_names.each do |question|
          exporter = CsvExporter.new(@report, question)
          exporter.export(@file_path)
        end
        create_zip_file
        load_zip_file
      ensure
        remove_export_directory
      end
      @report.zip_file
    end

    def create_export_directory
      # Remove any old export
      FileUtils.rmtree(@file_path) if File.exists? @file_path
      FileUtils.mkdir_p(@file_path)
    end

    def zip_path
      zip_path = "#{@file_path}/#{@report.report_name}.zip"
    end

    def create_zip_file
      files = Dir.glob(File.join(@file_path, '*')).map{ |path| File.basename(path) }
      Zip::File.open(zip_path, Zip::File::CREATE) do |zip_file|
        files.each do |file_name|
          zip_file.add(
            file_name,
            File.join(@file_path, file_name)
          )
        end
      end
    end

    def load_zip_file
      File.open(zip_path, 'rb') do |file|
        @report.update(zip_file: file.read)
      end
    end

    def remove_export_directory
      FileUtils.rmtree(@file_path) if File.exists? @file_path
    end
  end
end