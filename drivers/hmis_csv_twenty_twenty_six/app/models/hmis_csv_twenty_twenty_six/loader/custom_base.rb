###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvTwentyTwentySix::Loader
  class CustomBase < GrdaWarehouse::Hud::Base
    include LoaderConcern

    # Base class for all FY2026 custom loader classes, including dynamically generated ones
    # This provides common functionality for custom loader classes only
    # Standard loader classes inherit directly from GrdaWarehouse::Hud::Base

    # Default table name prefix for FY2026 loaders
    self.table_name_prefix = 'hmis_csv_2026_'

    # Method called by CustomFileManager when setting up generated classes
    # This executes the configuration logic directly in the class context
    def self.setup_model_for_file(file_config)
      setup_table_name(file_config)
      setup_configuration_methods(file_config)
      setup_class_methods(file_config)
    end

    private_class_method def self.setup_table_name(file_config)
      self.table_name = "hmis_csv_2026_#{file_config['class_name'].underscore.pluralize}"
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
    end

    # Generate class-specific singleton methods that depend on file configuration
    private_class_method def self.setup_class_methods(file_config)
      define_singleton_method(:hud_key) do
        (file_config['augment_key'] || file_config['warehouse_key'] || file_config['columns'].first['name'])&.to_sym
      end
    end

    # Loader tables store raw CSV data as strings
    # All validation and type conversion happens in the importer phase
  end
end
