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

    # Generates migration files for any missing custom file tables
    #
    # Reads all .yaml files from the custom config directory and creates
    # migration files for any tables that don't exist in the database.
    #
    # @return [void]
    def self.generate_custom_migrations!
      HmisCsvTwentyTwentySix.custom_files_config['custom_files'].each do |file_config|
        generate_migration_for_file(file_config)
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
        include HmisStructure::Base

        define_singleton_method(:hud_key) do
          file_config['augment_key'] || file_config['warehouse_key'] || file_config['columns'].first['name']
        end

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
        include HmisStructure::Base
        include HmisCsvTwentyTwentySix::Importer::CustomImportConcern
        setup_model_for_file(file_config)

        define_singleton_method(:custom_file_config) { file_config }

        define_singleton_method(:hud_key) do
          file_config['augment_key'] || file_config['warehouse_key'] || file_config['columns'].first['name']
        end

        # Set up destination_record association based on file configuration
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

    # Generates a migration file for a specific custom file if tables don't exist
    #
    # @param file_config [Hash] Configuration hash from YAML file
    # @return [void]
    # @private
    private_class_method def self.generate_migration_for_file(file_config)
      class_name = file_config['class_name']
      loader_table = "hmis_csv_2026_#{class_name.underscore.pluralize}"
      importer_table = "hmis_2026_#{class_name.underscore.pluralize}"

      # Check if tables exist
      loader_exists = ActiveRecord::Base.connection.table_exists?(loader_table)
      importer_exists = ActiveRecord::Base.connection.table_exists?(importer_table)

      return if loader_exists && importer_exists

      # Generate migration
      timestamp = Time.current.strftime('%Y%m%d%H%M%S')
      migration_name = "create_#{class_name.underscore}_custom_tables"
      migration_file = "db/warehouse/migrate/#{timestamp}_#{migration_name}.rb"

      migration_content = generate_migration_content(
        file_config: file_config,
        loader_table: loader_table,
        importer_table: importer_table,
        loader_exists: loader_exists,
        importer_exists: importer_exists,
        migration_name: migration_name,
      )

      File.write(Rails.root.join(migration_file), migration_content)
      puts "Generated migration: #{migration_file}"
    end

    # Generates the content for a migration file
    #
    # @param file_config [Hash] Configuration hash from YAML file
    # @param loader_table [String] Name of the loader table
    # @param importer_table [String] Name of the importer table
    # @param loader_exists [Boolean] Whether loader table exists
    # @param importer_exists [Boolean] Whether importer table exists
    # @param migration_name [String] Name of the migration class
    # @return [String] Migration file content
    # @private
    private_class_method def self.generate_migration_content(file_config:, loader_table:, importer_table:, loader_exists:, importer_exists:, migration_name:)
      class_name = migration_name.camelize

      content = <<~MIGRATION
        # frozen_string_literal: true

        class #{class_name} < ActiveRecord::Migration[7.1]
          def change
        #{generate_loader_table_migration(file_config, loader_table) unless loader_exists}
        #{generate_importer_table_migration(file_config, importer_table) unless importer_exists}
          end
        end
      MIGRATION

      content
    end

    # Generates loader table creation code
    #
    # @param file_config [Hash] Configuration hash from YAML file
    # @param table_name [String] Name of the loader table
    # @return [String] Migration code for loader table
    # @private
    private_class_method def self.generate_loader_table_migration(file_config, table_name)
      columns = file_config['columns'].map do |col|
        "      t.string \"#{col['name']}\""
      end.join("\n")

      <<~LOADER_TABLE
            # #{file_config['class_name']} loader table
            create_table :#{table_name} do |t|
        #{columns}

              # Standard loader columns
              t.references :data_source, null: false, index: true
              t.datetime :loaded_at, null: false
              t.references :loader, null: false, index: true
            end

            # Add indexes for loader table
            add_index :#{table_name}, [:#{file_config['columns'].first['name']}, :data_source_id], name: "idx_#{table_name.gsub('hmis_csv_2026_', '')}_id_ds"
      LOADER_TABLE
    end

    # Generates importer table creation code
    #
    # @param file_config [Hash] Configuration hash from YAML file
    # @param table_name [String] Name of the importer table
    # @return [String] Migration code for importer table
    # @private
    private_class_method def self.generate_importer_table_migration(file_config, table_name)
      columns = file_config['columns'].map do |col|
        column_type = case col['type']
        when 'integer' then 'integer'
        when 'datetime', 'date' then 'datetime'
        when 'boolean' then 'boolean'
        else 'string'
        end
        "      t.#{column_type} \"#{col['name']}\""
      end.join("\n")

      <<~IMPORTER_TABLE
            # #{file_config['class_name']} importer table
            create_table :#{table_name} do |t|
        #{columns}

              # Standard importer columns
              t.references :data_source, null: false, index: true
              t.references :importer_log, null: false, index: true
              t.datetime :pre_processed_at, null: false
              t.string :source_hash
              t.references :source, null: false, index: false
              t.string :source_type, null: false
              t.timestamp :dirty_at
              t.timestamp :clean_at
              t.boolean :should_import, default: true
            end

            # Add indexes for importer table
            add_index :#{table_name}, [:#{file_config['columns'].first['name']}, :data_source_id], name: "idx_#{table_name.gsub('hmis_2026_', '')}_imp_id_ds"
            add_index :#{table_name}, [:source_type, :source_id], name: "idx_#{table_name.gsub('hmis_2026_', '')}_source"
      IMPORTER_TABLE
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
