###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'csv'
require 'memoist'
module GrdaWarehouse::Tasks
  class HmisCsvValidator
    extend Memoist
    attr_accessor :errors, :project_ids, :enrollment_ids, :export_id, :path
    def initialize(path)
      @path = path
    end

    def run!
      return unless path.present? && File.directory?(path)

      Rails.logger.debug "Processing HMIS data from #{path}"
      HmisCsvTwentyTwentyTwo.importable_files_map.each do |filename, klass_name|
        Rails.logger.debug "Checking #{filename}"
        file_path = File.join(path, filename)
        downcase_converter = ->(header) { header.downcase }
        unique_keys = []
        export_ids = Set.new
        klass = "GrdaWarehouse::Hud::#{klass_name}".constantize
        if File.exist?(file_path)
          ::CSV.foreach(file_path, headers: true, header_converters: downcase_converter).each do |row|
            unique_keys << row[klass.hud_key.to_s.downcase]
            export_ids << row['exportid']
            self.export_id ||= row['exportid'] if filename == 'Export.csv'
            validate(filename, klass, row)
          end
        else
          puts "File not found: #{file_path}"
          Rails.logger.error "File not found: #{file_path}"
        end

        add_error(filename, klass.hud_key.to_s, "#{unique_keys.length - unique_keys.uniq.length} Duplicate unique keys found") if duplicate_keys?(unique_keys)
        add_error(filename, 'ExportID', 'Incorrect ExportIDs', export_ids.uniq) if incorrect_export_ids?(export_ids)
      end
    end

    private def validate(filename, klass, row)
      validations(klass).each do |column, checks|
        next unless checks.any?

        v = row[column.downcase]
        checks.each do |check|
          field_valid = if check[:limit].present?
            send(check[:check], v, check[:limit])
          else
            send(check[:check], v)
          end
          add_error(filename, column, check[:error_message], row.to_h) unless field_valid
        end
      end
    end

    private def add_error(filename, column, message, example = nil)
      self.errors ||= {}
      self.errors[filename] ||= {}
      self.errors[filename][column] ||= {}
      self.errors[filename][column][message] ||= { count: 0, example: example }
      self.errors[filename][column][message][:count] += 1
      self.errors[filename][column][message][:example] ||= example
    end

    private def validations(klass)
      klass.hmis_configuration(version: '2022').map do |column, structure|
        validation_methods = []
        validation_methods << case structure[:type]
        when :integer
          {
            error_message: 'Must be an integer',
            check: :integer_check,
          }
        when :date
          {
            error_message: 'Must be a date in format yyyy-mm-dd',
            check: :date_check,
          }
        when :datetime
          {
            error_message: 'Must be a time in format yyyy-mm-dd hh:mm:ss',
            check: :time_check,
          }
        end
        if structure[:check].present? && structure[:check] == :money
          validation_methods << {
            error_message: 'Must be a humber with two decimal places',
            check: :money_check,
          }
        end
        if structure[:limit].present?
          validation_methods << {
            error_message: 'Over-length',
            check: :length_check,
            limit: structure[:limit],
          }
        end
        if structure.key?(:null) && structure[:null] == false
          validation_methods << {
            error_message: 'Required',
            check: :required_field,
          }
        end
        [
          column.to_s,
          validation_methods.compact,
        ]
      end.to_h
    end
    memoize :validations

    private def duplicate_keys?(unique_keys)
      unique_keys.length != unique_keys.uniq.length
    end

    private def incorrect_export_ids?(export_ids)
      unique_export_ids = export_ids.uniq
      unique_export_ids.count > 1 || unique_export_ids.first != export_id
    end

    private def integer_check(value)
      return true unless value.present?

      value.to_i.to_s == value
    end

    private def date_check(value)
      return true unless value.present?

      value.match?(valid_date)
    end

    private def time_check(value)
      return true unless value.present?

      value.match?(valid_time)
    end

    private def money_check(value)
      return true unless value.present?

      format('%.2f', value.to_f) == value.to_s || value.to_i.to_s == value.to_s
    end

    private def length_check(value, length)
      value.to_s.length <= length
    end

    private def required_field(value)
      value.present?
    end

    private def valid_time
      @valid_time ||= /\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/
    end

    private def valid_date
      @valid_date ||= /\d{4}-\d{2}-\d{2}/
    end
  end
end
