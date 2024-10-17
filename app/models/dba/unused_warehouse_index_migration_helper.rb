###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# This code is probably only used once to identify indexes that are safe for removal.
require 'csv'
module Dba
  class UnusedWarehouseIndexMigrationHelper
    # filter the index definitions file to only those that are unused per the app stats
    # the results are intended to be included in a migration to drop the indexes
    # expects stats_directory_path to contain index stats from app monitor CSVs
    def self.perform(definitions_file_path:, stats_directory_path:)
      unused_indexes = find_unused_indexes_from_stats(stats_directory_path)
      File.readlines(definitions_file_path).map(&:chomp).filter do |definition|
        match = definition.match(/CREATE INDEX "?(?<index_name>[^"\s]+)"? ON (?:public\.)?(?<table>[^\s]+).*\((?<columns>.*)\)/)
        raise "Failed to parse index definition: #{definition}" unless match

        index_name = match[:index_name]
        unused_indexes.include?(index_name)
      end
    end

    # Given pg index stats from the AppInspector, find the set of indexes that are unused
    # An index is considered unused if it's unused in all CSVs where it appears
    def self.find_unused_indexes_from_stats(directory_path)
      csv_files = Dir.glob(File.join(directory_path, '*.csv'))
      csv_sets = csv_files.map { |file| process_csv(file) }

      all_indexes = csv_sets.each_with_object({}) do |csv_set, acc|
        csv_set.each do |index_name, is_unused|
          acc[index_name] ||= { unused_count: 0, total_count: 0 }
          acc[index_name][:unused_count] += 1 if is_unused
          acc[index_name][:total_count] += 1
        end
      end

      all_indexes.select { |_, stats| stats[:unused_count] == stats[:total_count] }.keys.to_set
    end

    # get the index names and their usage status
    def self.process_csv(file_path)
      index_status = {}

      CSV.foreach(file_path, headers: true) do |row|
        # symbolize keys for pattern matching
        case row.to_h.symbolize_keys
        in {
          database: /.*_warehouse\z/,
          tablename: /\Ahmis_(?:csv_)?202\d_/,
          number_of_scans: scans,
          tuples_read: read,
          tuples_fetched: fetched,
          index_name: index_name
        }
          is_unused = scans == '0' && read == '0' && fetched == '0'
          index_status[index_name] = is_unused
        else
          next
        end
      end

      index_status
    end
  end
end
