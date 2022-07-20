###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'csv'
module DatalabTestkit
  class TestkitCsvMerge
    def initialize(source_dirs, destination_dir)
      @source_dirs = source_dirs
      @destination_dir = destination_dir
    end

    def merge_dirs
      @source_dirs.each do |source_dir|
        puts "Merging #{source_dir}"
        merge_csvs(source_dir)
      end
    end

    def merge_csvs(source_dir)
      Dir.each_child(source_dir) do |filename|
        merge_csv(source_dir, filename)
      end
    end

    def merge_csv(source_dir, filename)
      source_table = CSV.read(File.join(source_dir, filename), headers: true)
      destination_file = File.join(@destination_dir, filename)
      dups = Set.new
      if File.exist?(destination_file)
        return if filename == 'Export.csv' # only process Export.csv once

        destination_table = CSV.read(destination_file)
        destination_table.each do |row|
          dups << row[0]
        end
      else
        destination_table = []
        destination_table << source_table.headers
      end

      source_table.each do |row|
        next if dups.include?(row[0])

        row['ExportID'] = 'MERGED-ID'
        destination_table << row.values_at
      end

      CSV.open(destination_file, 'wb') do |csv|
        destination_table.each do |row|
          csv << row
        end
      end
    end
  end
end
