###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvTwentyTwentySix
  # Manages dynamic generation of custom file models based on YAML configuration
  #
  # This class reads individual YAML files from drivers/hmis_csv_twenty_twenty_six/config/custom/
  # and generates corresponding Loader, Importer, and Warehouse models dynamically.
  #
  # @example YAML Configuration Structure
  #   # custom_gender.yaml
  #   custom_files:
  #     - filename: "CustomGender.csv"
  #       class_name: "CustomGender"
  #       required: false
  #       description: "Gender identity data in FY2024 format"
  #       augments_warehouse_table: "GrdaWarehouse::Hud::Client"
  #       augment_key: "PersonalID"
  #       columns:
  #         - name: "PersonalID"
  #           type: "string"
  #           required: true
  #           validations: ["NonBlank"]
  #         - name: "Woman"
  #           type: "integer"
  #           warehouse_column_mapping:
  #             type: "direct"
  #             target_column: "Woman"
  #
  # @example Usage
  #   # Generate all custom models before importing
  #   HmisCsvTwentyTwentySix::CustomFileManager.generate_custom_models!
  #
  #   # This creates:
  #   # - HmisCsvTwentyTwentySix::Loader::CustomGender
  #   # - HmisCsvTwentyTwentySix::Importer::CustomGender
  #   # - GrdaWarehouse::Hud::CustomDataElement (if creates_warehouse_table: true)
  #
  class CustomFileManager
    # Generates all custom models based on YAML configuration files
    #
    # Reads all .yaml files from the custom config directory and creates:
    # - Loader classes for raw CSV data storage
    # - Importer classes for processed data with validations
    # - Warehouse classes for final data storage (if specified)
    #
    # @return [void]
    def self.generate_custom_models!
      HmisCsvTwentyTwentySix.custom_files_config['custom_files'].each do |file_config|
        generate_loader_class(file_config)
        generate_importer_class(file_config)
        generate_warehouse_class(file_config) if file_config['creates_warehouse_table']
      end
    end

    # Creates a Loader class for storing raw CSV data
    #
    # @param file_config [Hash] Configuration hash from YAML file
    # @option file_config [String] :class_name Name of the class to generate
    # @option file_config [Array<Hash>] :columns Column definitions with validations
    # @return [void]
    def self.generate_loader_class(file_config)
      class_name = file_config['class_name']

      # Skip if class already exists
      return if loader_class_exists?(class_name)

      # Create loader class
      loader_class = Class.new(HmisCsvTwentyTwentySix::Loader::Base) do
        setup_model_for_file(file_config)
      end

      # Register the class
      HmisCsvTwentyTwentySix::Loader.const_set(class_name, loader_class)
    end

    # Creates an Importer class for processing and validating data
    #
    # @param file_config [Hash] Configuration hash from YAML file
    # @option file_config [String] :class_name Name of the class to generate
    # @option file_config [String] :augments_warehouse_table Optional table to augment
    # @option file_config [Boolean] :creates_warehouse_table Whether to create new warehouse table
    # @return [void]
    def self.generate_importer_class(file_config)
      class_name = file_config['class_name']

      # Skip if class already exists
      return if importer_class_exists?(class_name)

      # Create importer class
      importer_class = Class.new(HmisCsvTwentyTwentySix::Importer::Base) do
        include HmisCsvTwentyTwentySix::Importer::CustomImportConcern
        setup_model_for_file(file_config)

        define_singleton_method(:custom_file_config) { file_config }
      end

      # Register the class
      HmisCsvTwentyTwentySix::Importer.const_set(class_name, importer_class)
    end

    # Creates a Warehouse class for final data storage
    #
    # Only creates the class if creates_warehouse_table is true in the config
    #
    # @param file_config [Hash] Configuration hash from YAML file
    # @option file_config [String] :warehouse_class_name Full namespace path for the class
    # @return [void]
    def self.generate_warehouse_class(file_config)
      warehouse_class_name = file_config['warehouse_class_name']
      return if warehouse_class_exists?(warehouse_class_name)

      # Extract just the class name from the full path
      class_name = warehouse_class_name.split('::').last

      # Create warehouse class
      warehouse_class = Class.new(GrdaWarehouse::Base) do
        setup_hud_warehouse_model(file_config)
      end

      # Register the class in the appropriate namespace
      namespace = warehouse_class_name.split('::')[0..-2].join('::').constantize
      namespace.const_set(class_name, warehouse_class)
    end

    # Sets up the basic model structure for loader/importer classes
    #
    # @param file_config [Hash] Configuration hash from YAML file
    # @return [Proc] Proc that sets up the model when called in class context
    # @private
    private_class_method def self.setup_model_for_file(file_config)
      proc do
        self.table_name = "hmis_csv_twenty_twenty_six_#{file_config['class_name'].underscore.pluralize}"

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

    # Sets up warehouse model with standard HUD model behavior
    #
    # @param file_config [Hash] Configuration hash from YAML file
    # @return [Proc] Proc that sets up the warehouse model when called in class context
    # @private
    private_class_method def self.setup_hud_warehouse_model(file_config)
      proc do
        self.table_name = file_config['class_name'].underscore.pluralize.to_s

        # Standard HUD model setup
        include ArelHelper
        include HudSharedScopes
        acts_as_paranoid(column: :DateDeleted)

        # Define associations and validations based on file config
        file_config['columns'].each do |column_config|
          column_name = column_config['name']

          validates column_name, presence: true if column_config['required']
        end
      end
    end

    # Checks if a loader class already exists
    #
    # @param class_name [String] Name of the class to check
    # @return [Boolean] True if class exists
    # @private
    private_class_method def self.loader_class_exists?(class_name)
      HmisCsvTwentyTwentySix::Loader.const_defined?(class_name)
    end

    # Checks if an importer class already exists
    #
    # @param class_name [String] Name of the class to check
    # @return [Boolean] True if class exists
    # @private
    private_class_method def self.importer_class_exists?(class_name)
      HmisCsvTwentyTwentySix::Importer.const_defined?(class_name)
    end

    # Checks if a warehouse class already exists
    #
    # @param full_class_name [String] Full namespace path to the class
    # @return [Boolean] True if class exists
    # @private
    private_class_method def self.warehouse_class_exists?(full_class_name)
      full_class_name.safe_constantize.present?
    end
  end
end
