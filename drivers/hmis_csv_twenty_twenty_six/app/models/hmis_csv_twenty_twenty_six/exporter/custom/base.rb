###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvTwentyTwentySix::Exporter::Custom
  class Base
    include ArelHelper
    include TsqlImport
    include HmisCsvTwentyTwentySix::Exporter::ExportConcern

    attr_accessor :export, :batch_size

    def initialize(options)
      @options = options
      @export = options[:export]
      @batch_size = 10_000
    end

    def self.custom_file_name
      raise NotImplementedError, 'Custom exporters must define custom_file_name'
    end

    def file_name
      self.class.custom_file_name
    end

    def self.export_scope(batch_size: @batch_size)
      raise NotImplementedError, 'Custom exporters must define export_scope'
    end

    def transforms
      []
    end

    # Use the same pattern as standard exporters
    def self.temp_model_name
      "#{name.demodulize}Temp"
    end

    def temp_model_name
      self.class.temp_model_name
    end

    def self.hud_csv_file_name(_version: '2026')
      custom_file_name
    end

    def hud_csv_file_name(version: '2026')
      self.class.hud_csv_file_name(version: version)
    end

    # Override to provide custom CSV headers, excluding virtual columns
    def self.hmis_csv_headers(_version: '2026')
      definition = HmisCsvTwentyTwentySix.custom_files_config.find_definition(custom_file_name)
      return [] unless definition

      definition.columns.reject { |col| col['type'] == 'virtual' }.map { |col| col['name'] }
    end

    def hmis_csv_headers(version: '2026')
      self.class.hmis_csv_headers(version: version)
    end

    # Provide hmis_configuration by delegating to the associated importer class
    def self.hmis_configuration(version: '2026')
      # Find the corresponding importer class
      importer_class_name = name.gsub('::Exporter::', '::Importer::')
      begin
        importer_class = importer_class_name.constantize
        importer_class.hmis_configuration(version: version)
      rescue NameError
        Rails.logger.warn "Could not find importer class #{importer_class_name} for #{name}"
        {}
      end
    end

    def hmis_configuration(version: '2026')
      self.class.hmis_configuration(version: version)
    end

    # Creates a mapping of exporter class names to their required scope parameters
    # by extracting scope information from the main base exporter's class_mappings
    def self.exporter_scope_mapping
      @exporter_scope_mapping ||= begin
        mapping = {}
        HmisCsvTwentyTwentySix::Exporter::Base.class_mappings.each do |exporter_class, details|
          # Extract the class name (e.g., "Client" from "HmisCsvTwentyTwentySix::Exporter::Client")
          class_name = exporter_class.name.demodulize
          mapping[class_name] = details[:scope]
        end
        mapping.freeze
      end
    end

    # Generic export scope method for owner-based filtering
    # Override owner_class_mapping in subclasses to define which classes to loop over
    def self.export_scope_with_owner_filtering(**options)
      warehouse_class = warehouse_class_for_export

      # Create a union of scopes for each owner type, delegating to their export_scope
      scopes = []

      # Get the scope mapping from the custom base class
      scope_mapping = HmisCsvTwentyTwentySix::Exporter::Custom::Base.exporter_scope_mapping

      owner_class_mapping.each do |granular_class_name, owner_type|
        export_class = "HmisCsvTwentyTwentySix::Exporter::#{granular_class_name}".constantize
        next unless export_class.respond_to?(:export_scope)

        # Get the IDs of records being exported for this owner type
        # Each exporter requires different scope parameters, so we provide only what it needs
        required_scope_param = scope_mapping[granular_class_name]
        if required_scope_param && options.key?(required_scope_param)
          # Build the arguments hash with the required scope parameter, export, hmis_class, and temp_class
          class_mapping = HmisCsvTwentyTwentySix::Exporter::Base.class_mappings[export_class]
          hmis_class = class_mapping&.dig(:hmis_class)
          # Pass nil temp_class since we only need IDs, not full export functionality
          scope_args = { required_scope_param => options[required_scope_param], export: options[:export], hmis_class: hmis_class }
          # Special case client_scope as these return destination clients, but custom data elements are tied to the source client
          owner_ids_scope = if required_scope_param == :client_scope
            export_class.export_scope(**scope_args).joins(:warehouse_client_destination).select(wc_t[:source_id])
          else
            export_class.export_scope(**scope_args).select(:id)
          end
        else
          # Fallback: skip this exporter if we don't have the required scope
          Rails.logger.warn "Skipping #{granular_class_name} exporter - missing required scope #{required_scope_param}"
          next
        end

        # Find records that reference these exported records
        scope = warehouse_class.where(
          owner_type: owner_type,
          owner_id: owner_ids_scope,
        )
        scopes << scope
      end

      # Union all the scopes together
      return warehouse_class.none if scopes.empty?

      combined_scope = scopes.shift
      scopes.each do |scope|
        combined_scope = combined_scope.or(scope)
      end

      combined_scope
    end

    # Override this method in subclasses to define which classes to loop over
    def self.owner_class_mapping
      raise NotImplementedError, 'Subclasses must define owner_class_mapping'
    end

    # Override this method in subclasses to define the warehouse class
    def self.warehouse_class_for_export
      raise NotImplementedError, 'Subclasses must define warehouse_class_for_export'
    end

    # Maps warehouse column values to export column values for custom files
    # This reverses the warehouse_column_mapping defined in the YAML configuration
    def self.apply_warehouse_to_export_mappings(row)
      definition = HmisCsvTwentyTwentySix.custom_files_config.find_definition(custom_file_name)
      return row unless definition

      row = row.attributes.with_indifferent_access

      definition.columns.each do |column_config|
        export_column = column_config['name']
        mapping = column_config['warehouse_column_mapping']
        next unless mapping

        case mapping['type']
        when 'direct', 'record_lookup'
          warehouse_column = mapping['target_column']
          row[export_column] = row[warehouse_column] if warehouse_column
        when 'value_mapping'
          warehouse_column = mapping['target_column']
          value_mappings = mapping['value_mappings'] || {}
          if warehouse_column
            warehouse_value = row[warehouse_column]
            # Reverse lookup: find export value for warehouse value
            export_value = value_mappings.key(warehouse_value) || warehouse_value
            row[export_column] = export_value
          end
        end
      end

      row
    end

    private

    # Helper method to get the custom file definition
    def custom_file_definition
      @custom_file_definition ||= HmisCsvTwentyTwentySix.custom_files_config.find_definition(file_name)
    end
  end
end
