###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Run with:
# r = HudLsa::Generators::Fy2027::LsaComparisonTool.new('var/lsa/sample', 'var/lsa/generated')
# r.compare
require 'csv'
module HudLsa::Generators::Fy2027
  class LsaComparisonTool
    attr_accessor :sample_data_path, :generated_data_path, :skips, :skipped_files, :unmatched_generated_files

    # skips: { 'SomeFile.csv' => {
    #   skip_file: true,             # ignore this file entirely (still reported, just not compared)
    #   columns: ['SomeColumn'],     # additional columns to drop from every row before comparing
    #   rows: { 'SomeColumn' => ['1', '2'] }, # drop any row (either side) whose SomeColumn is '1' or '2'
    # } }
    def initialize(sample_data_path, generated_data_path, skips: {})
      @sample_data_path = sample_data_path
      @generated_data_path = generated_data_path
      @skips = skips
      @skipped_files = []
      @unmatched_generated_files = []
    end

    def compare
      comparisons = {}
      sample_basenames = sample_data.map { |f| File.basename(f) }
      sample_data.each do |filepath|
        if skip_file?(filepath)
          skipped_files << File.basename(filepath)
          next
        end

        comparisons[filepath] = generate_diff(filepath, generated_data(filepath))
      end
      @unmatched_generated_files = generated_data_basenames.reject { |name| sample_basenames.include?(name) || skip_file_by_name?(name) }
      comparisons
    end

    def sample_data
      Dir.glob("#{sample_data_path}/*")
    end

    def generated_data(filepath)
      @generated_data ||= Dir.glob("#{generated_data_path}/*").index_by { |f| File.basename(f) }
      @generated_data[File.basename(filepath)]
    end

    def generated_data_basenames
      Dir.glob("#{generated_data_path}/*").map { |f| File.basename(f) }
    end

    def generate_diff(sample, gen)
      raise "no generated file found matching #{File.basename(sample)} (looked in #{generated_data_path})" if gen.nil?

      {
        'sample - generated' => file_contents(sample) - file_contents(gen),
        'generated - sample' => file_contents(gen) - file_contents(sample),
      }
    end

    def file_contents(filename)
      file_skips = skips[File.basename(filename)] || {}
      skip_columns = removed_keys + Array(file_skips[:columns])
      row_skips = file_skips[:rows] || {}

      [].tap do |data|
        CSV.foreach(filename, headers: true) do |row|
          hash = row.to_h
          next if row_skips.any? { |column, values| values.include?(hash[column]) }

          data << hash.except(*skip_columns).values.map(&:to_s)
        end
      end.sort
    end

    # These keys will differ by run/installation, so just ignore them
    def removed_keys
      [
        'FunderID',
        'ProjectID',
        'ExportID',
        'InventoryID',
        'ReportID',
        'ReportDate',
        'SoftwareVendor',
        'SoftwareName',
        'VendorContact',
        'VendorEmail',
        'OrganizationID',
        'ProjectCoCID',
        'AffiliationID',
        'HMISParticipationID',
        'PITCount',
      ]
    end

    private def skip_file?(filepath)
      skip_file_by_name?(File.basename(filepath))
    end

    private def skip_file_by_name?(basename)
      skips.dig(basename, :skip_file)
    end
  end
end
