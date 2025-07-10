###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvTwentyTwentySix::Importer
  class CustomBase < GrdaWarehouse::Hud::Base
    include ImportConcern

    # Base class for all FY2026 custom importer classes, including dynamically generated ones
    # This provides common functionality for custom importer classes only
    # Standard importer classes inherit directly from GrdaWarehouse::Hud::Base

    # Default table name prefix for FY2026 importers
    self.table_name_prefix = 'hmis_2026_'

    # Method called by CustomFileManager when setting up generated classes
    # This executes the configuration logic directly in the class context
    #
    # Method Organization for Custom Importer Classes:
    #
    # 1. setup_model_for_file (this method) - All configuration-driven setup
    #    - Table names, column definitions, validations
    #    - Methods that depend on YAML configuration
    #
    # 2. CustomImportConcern - Behavioral overrides only
    #    - Methods that change how the import process works
    #    - Overrides for augmentation vs. new table creation
    #    - Delegation to other classes
    #
    # 3. generate_importer_class (custom_file_manager.rb) - Class creation only
    #    - Class instantiation and module inclusion
    #    - Calls setup_model_for_file
    #    - Registers the class in the namespace
    def self.setup_model_for_file(file_config)
      setup_table_name(file_config)
      setup_configuration_methods(file_config)
      setup_class_methods(file_config)
      setup_associations(file_config)
      setup_validations(file_config)
    end

    private_class_method def self.setup_table_name(file_config)
      self.table_name = "hmis_2026_#{file_config['class_name'].underscore.pluralize}"
    end

    # Generate configuration-driven singleton methods based on YAML column configuration
    private_class_method def self.setup_configuration_methods(file_config)
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
        # Return all HMIS data columns
        # Remove DateCreated, DateUpdated, DateDeleted, ExportID, UserID if this is an augmentation
        # Note: version parameter is required by ImportConcern interface but not used
        # for custom files since structure comes from YAML configuration
        excluded_augmentation_columns = ['DateCreated', 'DateUpdated', 'DateDeleted', 'ExportID', 'UserID']
        hmis_columns = file_config['columns'].map { |col| col['name'] }

        excluded_columns = augments? ? excluded_augmentation_columns : []
        (hmis_columns - excluded_columns).map(&:to_sym)
      end
    end

    # Generate class-specific singleton methods that depend on file configuration
    private_class_method def self.setup_class_methods(file_config)
      define_singleton_method(:custom_file_config) { file_config }

      define_singleton_method(:hud_key) do
        (file_config['augment_key'] || file_config['warehouse_key'] || file_config['columns'].first['name'])&.to_sym
      end
    end

    # Set up destination_record association based on file configuration
    private_class_method def self.setup_associations(file_config)
      if file_config['augments_warehouse_table']
        # For files that augment existing warehouse tables
        warehouse_class = file_config['augments_warehouse_table']
        key_column = file_config['augment_key'] || file_config['columns'].first['name']
        model_name = warehouse_class.split('::').last

        has_one :destination_record, **hud_assoc(key_column.to_sym, model_name)
      elsif file_config['creates_warehouse_table']
        # For files that create new warehouse tables
        warehouse_class_name = file_config['warehouse_class_name']
        key_column = file_config['warehouse_key'] || file_config['columns'].first['name']
        model_name = warehouse_class_name.split('::').last

        has_one :destination_record, **hud_assoc(key_column.to_sym, model_name)
      end
    end

    # Define column mappings and validations based on YAML configuration
    private_class_method def self.setup_validations(file_config)
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
