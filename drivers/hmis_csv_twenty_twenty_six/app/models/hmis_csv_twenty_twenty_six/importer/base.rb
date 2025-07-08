###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvTwentyTwentySix::Importer
  class Base < GrdaWarehouse::Hud::Base
    include ImportConcern

    # Base class for all FY2026 importer classes, including dynamically generated ones
    # This provides common functionality for both standard and custom importer classes

    # Default table name prefix for FY2026 importers
    self.table_name_prefix = 'hmis_2026_'

    # Method called by CustomFileManager when setting up generated classes
    # This executes the configuration logic directly in the class context
    def self.setup_model_for_file(file_config)
      self.table_name = "hmis_2026_#{file_config['class_name'].underscore.pluralize}"

      # Generate hud_csv_headers method based on YAML column configuration
      column_names = file_config['columns'].map { |col| col['name'] }

      define_singleton_method(:hud_csv_headers) do
        column_names
      end

      # Generate hmis_structure method based on YAML column configuration
      # This returns a hash where keys are column names (as symbols) and values are column metadata
      hmis_structure_hash = file_config['columns'].each_with_object({}) do |col, hash|
        hash[col['name'].to_sym] = {
          type: col['type'] || 'string',
          required: col['required'] || false,
        }
      end

      define_singleton_method(:hmis_structure) do
        hmis_structure_hash
      end

      # Generate upsert_column_names method based on YAML column configuration
      # This returns the columns that should be included in upsert operations
      define_singleton_method(:upsert_column_names) do |version: hud_csv_version| # rubocop:disable Lint/UnusedBlockArgument
        # Return all HMIS data columns plus framework columns for upserts
        # Note: version parameter is required by ImportConcern interface but not used
        # for custom files since structure comes from YAML configuration
        hmis_columns = file_config['columns'].map { |col| col['name'] }
        framework_columns = [
          'data_source_id',
          'importer_log_id',
          'pre_processed_at',
          'source_hash',
          'source_id',
          'source_type',
          'dirty_at',
          'clean_at',
          'should_import',
        ]

        (hmis_columns + framework_columns).map(&:to_sym)
      end

      # Define column mappings and validations
      file_config['columns'].each do |column_config|
        column_name = column_config['name']
        column_type = column_config['type']

        # Add basic validations
        validates column_name, presence: true if column_config['required']

        validates column_name, length: { maximum: column_config['max_length'] } if column_config['max_length']

        # Add type-specific validations
        case column_type
        when 'integer'
          validates column_name, numericality: { only_integer: true }, allow_blank: true
        when 'date', 'datetime'
          # Date/datetime validation is handled by ActiveRecord type casting
          # But we can add custom format validation if needed
        when 'boolean'
          validates column_name, inclusion: { in: [true, false, 0, 1, '0', '1', 'true', 'false'] }, allow_blank: true
        end

        # Add custom validations from YAML
        next unless column_config['validations']

        column_config['validations'].each do |validation|
          if validation.is_a?(String)
            case validation
            when 'NonBlank'
              validates column_name, presence: true
            end
          elsif validation.is_a?(Hash)
            validation_class = validation['class']
            arguments = validation['arguments'] || {}

            case validation_class
            when 'InclusionInSet'
              validates column_name, inclusion: { in: arguments['valid_options'] }
            end
          end
        end
      end
    end
  end
end
