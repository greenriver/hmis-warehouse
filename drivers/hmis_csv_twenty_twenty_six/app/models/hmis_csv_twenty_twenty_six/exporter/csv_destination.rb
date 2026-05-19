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
      config = options[:hmis_class].hmis_configuration(version: '2026')
      @keys = config.keys
      @money_keys = config.filter_map { |k, m| k if m[:check] == :money }.to_set
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
      values = row.values_at(*@keys)
      # AR type-casts string values back to BigDecimal for numeric columns on read;
      # re-apply formatting here after values_at to guarantee two-decimal output.
      @keys.each_with_index do |key, i|
        next unless @money_keys.include?(key) && values[i]

        values[i] = format('%.2f', values[i])
      end
      @csv << values
    end

    def close
      @csv&.close
    end
  end
end
