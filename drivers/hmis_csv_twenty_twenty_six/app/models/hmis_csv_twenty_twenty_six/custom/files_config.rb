###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvTwentyTwentySix
  module Custom
    # Simple wrapper that holds FileDefinition objects for custom files
    class FilesConfig
      attr_reader :definitions

      def initialize(config_dir = nil)
        config_dir ||= Rails.root.join('drivers', 'hmis_csv_twenty_twenty_six', 'config', 'custom')
        all_custom_files = []

        if Dir.exist?(config_dir)
          Dir.glob(File.join(config_dir, '*.yaml')).sort.each do |config_file|
            config = YAML.load_file(config_file, permitted_classes: [Date, Time])
            if config && config['custom_files'].is_a?(Array)
              all_custom_files.concat(config['custom_files'])
            else
              Rails.logger.warn "Custom file config #{config_file} has invalid structure - expecting 'custom_files' array"
            end
          rescue StandardError => e
            Rails.logger.error "Failed to load custom file config #{config_file}: #{e.message}"
            raise e if Rails.env.development? || Rails.env.test?
          end
        end

        @definitions = all_custom_files.map do |config|
          FileDefinition.new(config)
        end
      end

      def find_definition(filename)
        @definitions.find { |d| d.filename == filename }
      end

      def required_filenames
        @definitions.select(&:required?).map(&:filename)
      end

      def class_name_mapping
        @definitions.map { |d| [d.filename, "Custom::#{d.class_name}"] }.to_h
      end
    end
  end
end
