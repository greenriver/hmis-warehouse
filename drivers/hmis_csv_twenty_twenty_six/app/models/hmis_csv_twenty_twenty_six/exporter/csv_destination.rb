###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvTwentyTwentySix::Exporter
  class CsvDestination
    attr_reader :output_file

    def initialize(options)
      @output_file = options[:output_file]
      @config = options[:hmis_class].hmis_configuration(version: '2026')
      @keys = @config.keys
      # Cached here so write() can format money/integer fields without re-reading config per row.
      @rounded_columns = @config.select { |_, m| m[:check].in?([:money, :integer]) }
      @strip_newline_proc = proc do |field|
        field.respond_to?(:gsub) ? field.gsub("\n", '\\n') : field
      end

      @csv ||= CSV.open(@output_file, 'wb', force_quotes: true, write_converters: [@strip_newline_proc])
      return if @headers_written

      @headers_written = true
      @csv << options[:destination_class].csv_header_override(@keys)
    end

    def write(row)
      @csv ||= CSV.open(@output_file, 'wb', force_quotes: true, write_converters: [@strip_newline_proc])
      # Build a plain hash from the AR object using spec column names as keys. Rounding is
      # applied here rather than in ExportConcern#process because AR silently re-casts string
      # values (e.g. "50.00") back to numeric types on assignment, corrupting the formatted output.
      hash = @keys.map { |k| [k, row[k]] }.to_h
      @rounded_columns.each do |k, opts|
        hash = HmisCsvTwentyTwentySix::Exporter::IncomeBenefit.round_value(hash, hud_field: k, rounding: opts[:check], positive: opts[:positive])
      end
      @csv << hash.values_at(*@keys)
    end

    def close
      @csv&.close
    end
  end
end
