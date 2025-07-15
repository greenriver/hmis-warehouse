###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvTwentyTwentySix::Importer::Custom
  # Handles column mapping from custom CSV files to warehouse tables
  #
  # This class provides generic mapping functionality that can transform
  # data from custom CSV files into the appropriate warehouse format
  # based on YAML configuration. It supports three main mapping types:
  #
  # 1. **Direct mapping**: Simple 1:1 column mapping
  # 2. **Value-based multi-column mapping**: Maps source values to different target columns
  # 3. **Concatenation mapping**: Combines multiple source values into one target column
  # 4. **Key-value store processing**: Special handling for CustomDataElements
  #
  # == Usage Patterns
  #
  # The ColumnMapper is typically used in two scenarios:
  # 1. **Augmentation**: Adding data to existing warehouse tables
  # 2. **Key-value processing**: Handling CustomDataElements with definitions
  #
  # == Mapping Configuration Examples
  #
  # @example Direct mapping (1:1 column mapping)
  #   # YAML config:
  #   warehouse_column_mapping:
  #     type: "direct"
  #     target_column: "Woman"
  #
  #   # Usage:
  #   ColumnMapper.apply_mappings(source_record, mapped_attrs, column_configs)
  #
  # @example Value-based multi-column mapping (coded values to multiple columns)
  #   # YAML config:
  #   warehouse_column_mapping:
  #     type: "value_based_multi_column"
  #     value_mappings:
  #       - condition: { value: "1" }
  #         target_column: "Woman"
  #         target_value: 1
  #       - condition: { value: "2" }
  #         target_column: "Man"
  #         target_value: 1
  #
  #   # This maps gender codes to separate boolean columns
  #
  # @example Concatenation mapping (multiple sources to one target)
  #   # YAML config:
  #   warehouse_column_mapping:
  #     type: "concatenation"
  #     target_column: "combined_notes"
  #     separator: " | "
  #
  #   # Combines values like "Note 1 | Note 2 | Note 3"
  #
  # @example Key-value store processing
  #   # For CustomDataElements that reference definitions:
  #   ColumnMapper.process_key_value_store(source_records, file_config, importer_log)
  #
  # == Error Handling
  #
  # The mapper handles various error conditions gracefully:
  # - Unknown mapping types are logged as warnings
  # - Invalid data conversions return nil or default values
  # - Missing definitions in key-value stores are logged as warnings
  #
  # @see CustomImportConcern For integration with importer classes
  # @see CustomFileManager For YAML configuration loading
  class ColumnMapper
    # Applies column mappings from source record to target attributes with efficient record lookup support
    #
    # This method supports a two-phase process:
    # 1. Apply all standard mappings (direct, value_mapping, etc.)
    # 2. Handle record_lookup mappings in batches for performance
    #
    # @param source_records [Array<Object>] Array of source records to process
    # @param column_configs [Array<Hash>] Array of column configurations from YAML
    # @return [Array<Hash>] Array of mapped attributes for each record
    def self.apply_mappings_batch(source_records, column_configs)
      # Phase 1: Apply all standard mappings
      results = source_records.map do |source_record|
        mapped_attributes = {}
        apply_standard_mappings(source_record, mapped_attributes, column_configs)
        { source_record: source_record, mapped_attributes: mapped_attributes }
      end

      # Phase 2: Handle record lookups in batches
      apply_record_lookups_batch(results, column_configs)

      results.map { |result| result[:mapped_attributes] }
    end

    # Applies column mappings with efficient batch record lookups
    #
    # This method supports both single record and batch processing modes.
    # For record_lookup mappings, it defers the lookup and handles them efficiently.
    #
    # @param source_record [Object] Source record with data to map
    # @param mapped_attributes [Hash] Hash to store mapped attributes
    # @param column_configs [Array<Hash>] Array of column configurations from YAML
    # @param lookup_cache [Hash, nil] Optional cache for record lookups (for batch processing)
    # @return [void]
    def self.apply_mappings(source_record, mapped_attributes, column_configs, lookup_cache: nil)
      column_configs.each do |column_config|
        column_name = column_config['name']
        value = source_record[column_name]

        # Default to direct mapping with same column name if no mapping specified
        mapping_config = column_config['warehouse_column_mapping'] || {}
        mapping_config = apply_mapping_defaults(mapping_config, column_name)

        case mapping_config['type']
        when 'direct'
          apply_direct_mapping(mapped_attributes, value, mapping_config)
        when 'value_based_multi_column'
          apply_value_based_multi_column_mapping(mapped_attributes, value, mapping_config)
        when 'concatenation'
          apply_concatenation_mapping(mapped_attributes, value, mapping_config)
        when 'value_mapping'
          apply_value_mapping(mapped_attributes, value, mapping_config)
        when 'record_lookup'
          apply_record_lookup_mapping(source_record, mapped_attributes, mapping_config, lookup_cache)
        when 'static_value'
          apply_static_value_mapping(mapped_attributes, mapping_config)
        else
          Rails.logger.warn "Unknown mapping type: #{mapping_config['type']}"
        end
      end
    end

    # Applies all standard (non-record-lookup) mappings
    #
    # @param source_record [Object] Source record with data to map
    # @param mapped_attributes [Hash] Hash to store mapped attributes
    # @param column_configs [Array<Hash>] Array of column configurations from YAML
    # @return [void]
    # @private
    private_class_method def self.apply_standard_mappings(source_record, mapped_attributes, column_configs)
      column_configs.each do |column_config|
        column_name = column_config['name']
        value = source_record[column_name]

        # Default to direct mapping with same column name if no mapping specified
        mapping_config = column_config['warehouse_column_mapping'] || {}
        mapping_config = apply_mapping_defaults(mapping_config, column_name)

        case mapping_config['type']
        when 'direct'
          apply_direct_mapping(mapped_attributes, value, mapping_config)
        when 'value_based_multi_column'
          apply_value_based_multi_column_mapping(mapped_attributes, value, mapping_config)
        when 'concatenation'
          apply_concatenation_mapping(mapped_attributes, value, mapping_config)
        when 'value_mapping'
          apply_value_mapping(mapped_attributes, value, mapping_config)
        when 'record_lookup'
          # Skip record lookups in phase 1 - they'll be handled in batch in phase 2
          next
        when 'static_value'
          apply_static_value_mapping(mapped_attributes, mapping_config)
        else
          Rails.logger.warn "Unknown mapping type: #{mapping_config['type']}"
        end
      end
    end

    # Applies record lookup mappings in batches for performance
    #
    # This method efficiently handles record lookups by:
    # 1. Collecting all lookups needed grouped by class and data source
    # 2. Executing batch queries for each class
    # 3. Applying results back to the mapped attributes
    #
    # @param results [Array<Hash>] Array of { source_record:, mapped_attributes: } hashes
    # @param column_configs [Array<Hash>] Array of column configurations from YAML
    # @return [void]
    # @private
    private_class_method def self.apply_record_lookups_batch(results, column_configs)
      record_lookup_configs = column_configs.select { |col| col.dig('warehouse_column_mapping', 'type') == 'record_lookup' }
      return if record_lookup_configs.empty?

      # Collect all lookups needed
      lookups_by_class = {}

      record_lookup_configs.each do |column_config|
        column_name = column_config['name']
        mapping_config = column_config['warehouse_column_mapping']
        class_column = mapping_config['class_column']
        target_column = mapping_config['target_column']
        lookup_field_mappings = mapping_config['lookup_field_mappings']

        results.each_with_index do |result, index|
          source_record = result[:source_record]
          mapped_attributes = result[:mapped_attributes]

          record_id_value = source_record[column_name]
          class_name = mapped_attributes[class_column]
          data_source_id = source_record.data_source_id

          next if record_id_value.blank? || class_name.blank?

          lookup_field = lookup_field_mappings[class_name]
          next if lookup_field.blank?

          # Group by class and data source for efficient batching
          key = [class_name, data_source_id]
          lookups_by_class[key] ||= {
            class_name: class_name,
            data_source_id: data_source_id,
            lookup_field: lookup_field,
            values: [],
            mappings: [],
          }
          lookups_by_class[key][:values] << record_id_value
          lookups_by_class[key][:mappings] << {
            result_index: index,
            target_column: target_column,
            source_value: record_id_value,
          }
        end
      end

      # Execute batch queries and apply results
      lookups_by_class.each do |_key, lookup_info|
        apply_batch_lookup(lookup_info, results)
      end
    end

    # Executes a batch lookup for a specific class and applies results
    #
    # @param lookup_info [Hash] Information about the lookup to perform
    # @param results [Array<Hash>] Array of result hashes to update
    # @return [void]
    # @private
    private_class_method def self.apply_batch_lookup(lookup_info, results)
      class_name = lookup_info[:class_name]
      data_source_id = lookup_info[:data_source_id]
      lookup_field = lookup_info[:lookup_field]
      values = lookup_info[:values].uniq
      mappings = lookup_info[:mappings]

      return if values.empty?

      # Execute the batch query

      klass = class_name.constantize
      query = klass.where(lookup_field => values, data_source_id: data_source_id)

      # Create lookup hash: source_value -> database_id
      lookup_results = query.pluck(lookup_field, :id).to_h

      # Apply results back to mapped attributes
      mappings.each do |mapping|
        result_index = mapping[:result_index]
        target_column = mapping[:target_column]
        source_value = mapping[:source_value]

        database_id = lookup_results[source_value]
        if database_id
          results[result_index][:mapped_attributes][target_column] = database_id
        else
          Rails.logger.warn "Record lookup failed: #{class_name} with #{lookup_field}=#{source_value} not found"
          # Leave the target column nil or set to a default value
          results[result_index][:mapped_attributes][target_column] = nil
        end
      end
    end

    # Applies default values to mapping configuration
    #
    # This method provides sensible defaults for mapping configurations:
    # - Defaults to 'direct' mapping type if not specified
    # - Defaults target_column to the same as source column name if not specified
    #
    # @param mapping_config [Hash] The mapping configuration (may be empty)
    # @param column_name [String] The source column name
    # @return [Hash] The mapping configuration with defaults applied
    #
    # @example Default behavior
    #   # For a column named "UserID" with no mapping config
    #   apply_mapping_defaults({}, "UserID")
    #   # => { "type" => "direct", "target_column" => "UserID" }
    #
    #   # For a column with partial config
    #   apply_mapping_defaults({ "type" => "value_mapping" }, "RecordType")
    #   # => { "type" => "value_mapping", "target_column" => "RecordType" }
    #
    # @private
    private_class_method def self.apply_mapping_defaults(mapping_config, column_name)
      mapping_config = mapping_config.dup
      mapping_config['type'] ||= 'direct'
      mapping_config['target_column'] ||= column_name
      mapping_config
    end

    # Applies direct column mapping from source to target
    #
    # This is the simplest mapping type where the source value is directly
    # copied to the target column without any transformation.
    #
    # @param mapped_attributes [Hash] Hash to store the mapped attributes
    # @param value [Object] The source value to map
    # @param mapping_config [Hash] Configuration containing the target column
    # @option mapping_config [String] :target_column The name of the target column
    # @return [void]
    #
    # @example Direct mapping
    #   mapped_attributes = {}
    #   apply_direct_mapping(mapped_attributes, "John", { "target_column" => "first_name" })
    #   # mapped_attributes now contains: { "first_name" => "John" }
    #
    # @private
    private_class_method def self.apply_direct_mapping(mapped_attributes, value, mapping_config)
      mapped_attributes[mapping_config['target_column']] = value
    end

    # Applies value-based multi-column mapping
    #
    # This mapping type allows different source values to be mapped to different
    # target columns with potentially different target values. It's useful for
    # transforming coded values into multiple boolean or flag columns.
    #
    # @param mapped_attributes [Hash] Hash to store the mapped attributes
    # @param value [Object] The source value to evaluate
    # @param mapping_config [Hash] Configuration containing the mapping rules
    # @option mapping_config [Array<Hash>] :value_mappings Array of mapping rules
    # @return [void]
    #
    # @example Value-based mapping for gender
    #   # YAML config:
    #   # value_mappings:
    #   #   - condition: { value: "1" }
    #   #     target_column: "Woman"
    #   #     target_value: 1
    #   #   - condition: { value: "2" }
    #   #     target_column: "Man"
    #   #     target_value: 1
    #
    #   mapped_attributes = {}
    #   config = {
    #     "value_mappings" => [
    #       { "condition" => { "value" => "1" }, "target_column" => "Woman", "target_value" => 1 }
    #     ]
    #   }
    #   apply_value_based_multi_column_mapping(mapped_attributes, "1", config)
    #   # mapped_attributes now contains: { "Woman" => 1 }
    #
    # @private
    private_class_method def self.apply_value_based_multi_column_mapping(mapped_attributes, value, mapping_config)
      mapping_config['value_mappings'].each do |mapping|
        mapped_attributes[mapping['target_column']] = mapping['target_value'] if mapping['condition']['value'] == value
      end
    end

    # Applies concatenation mapping to combine multiple values
    #
    # This mapping type concatenates the source value with any existing value
    # in the target column, using a configurable separator. It's useful for
    # building composite fields from multiple source columns.
    #
    # @param mapped_attributes [Hash] Hash to store the mapped attributes
    # @param value [Object] The source value to concatenate
    # @param mapping_config [Hash] Configuration containing target column and separator
    # @option mapping_config [String] :target_column The name of the target column
    # @option mapping_config [String] :separator The separator to use (default: ' ')
    # @return [void]
    #
    # @example Concatenation mapping
    #   mapped_attributes = { "full_name" => "John" }
    #   config = { "target_column" => "full_name", "separator" => " " }
    #   apply_concatenation_mapping(mapped_attributes, "Doe", config)
    #   # mapped_attributes now contains: { "full_name" => "John Doe" }
    #
    # @example With custom separator
    #   mapped_attributes = { "tags" => "urgent" }
    #   config = { "target_column" => "tags", "separator" => ", " }
    #   apply_concatenation_mapping(mapped_attributes, "priority", config)
    #   # mapped_attributes now contains: { "tags" => "urgent, priority" }
    #
    # @private
    private_class_method def self.apply_concatenation_mapping(mapped_attributes, value, mapping_config)
      existing_value = mapped_attributes[mapping_config['target_column']] || ''
      separator = mapping_config['separator'] || ' '
      mapped_attributes[mapping_config['target_column']] = [existing_value, value].reject(&:blank?).join(separator)
    end

    # Applies value mapping based on configuration.
    #
    # This method handles transformations where a source value needs to be mapped
    # to a different target value based on a lookup table. It's useful for
    # transforming coded values or translating between different naming conventions.
    #
    # @param mapped_attributes [Hash] Hash to store the mapped attributes
    # @param value [Object] The source value to transform
    # @param mapping_config [Hash] Configuration containing the mapping rules
    # @option mapping_config [String] :target_column The name of the target column
    # @option mapping_config [Hash] :value_mappings Hash mapping source values to target values
    # @return [void]
    #
    # @example Value mapping for record type transformation
    #   # YAML config:
    #   # warehouse_column_mapping:
    #   #   type: "value_mapping"
    #   #   target_column: "owner_type"
    #   #   value_mappings:
    #   #     "Client": "GrdaWarehouse::Hud::Client"
    #   #     "Enrollment": "GrdaWarehouse::Hud::Enrollment"
    #
    #   mapped_attributes = {}
    #   config = {
    #     "target_column" => "owner_type",
    #     "value_mappings" => {
    #       "Client" => "GrdaWarehouse::Hud::Client",
    #       "Enrollment" => "GrdaWarehouse::Hud::Enrollment"
    #     }
    #   }
    #   apply_value_mapping(mapped_attributes, "Client", config)
    #   # mapped_attributes now contains: { "owner_type" => "GrdaWarehouse::Hud::Client" }
    #
    # @private
    private_class_method def self.apply_value_mapping(mapped_attributes, value, mapping_config)
      target_column = mapping_config['target_column']
      value_mappings = mapping_config['value_mappings']

      # Use the mapped value if it exists, otherwise use the original value
      transformed_value = value_mappings[value] || value
      mapped_attributes[target_column] = transformed_value
    end

    # Applies static value mapping from source to target
    #
    # This mapping type sets a static value for a target column.
    #
    # @param mapped_attributes [Hash] Hash to store the mapped attributes
    # @param mapping_config [Hash] Configuration containing the target column and value
    # @option mapping_config [String] :target_column The name of the target column
    # @option mapping_config [Object] :value The static value to set
    # @return [void]
    #
    # @example Static value mapping
    #   mapped_attributes = {}
    #   config = { "target_column" => "data_element_definition_id", "value" => 0 }
    #   apply_static_value_mapping(mapped_attributes, config)
    #   # mapped_attributes now contains: { "data_element_definition_id" => 0 }
    #
    # @private
    private_class_method def self.apply_static_value_mapping(mapped_attributes, mapping_config)
      mapped_attributes[mapping_config['target_column']] = mapping_config['value']
    end

    # Checks if any column configurations require record lookups
    #
    # @param column_configs [Array<Hash>] Array of column configurations from YAML
    # @return [Boolean] True if any columns use record_lookup mapping type
    def self.record_lookups?(column_configs)
      column_configs.any? { |col| col.dig('warehouse_column_mapping', 'type') == 'record_lookup' }
    end

    # Applies record lookup mapping with optional caching for batch processing
    #
    # @param source_record [Object] Source record with data to map
    # @param mapped_attributes [Hash] Hash to store mapped attributes
    # @param mapping_config [Hash] Configuration for the record lookup
    # @param lookup_cache [Hash, nil] Optional cache for record lookups
    # @return [void]
    # @private
    private_class_method def self.apply_record_lookup_mapping(source_record, mapped_attributes, mapping_config, lookup_cache)
      class_column = mapping_config['class_column']
      target_column = mapping_config['target_column']
      lookup_field_mappings = mapping_config['lookup_field_mappings']
      source_column = mapping_config['source_column'] || 'RecordID'

      # Get the source values
      source_value = source_record[source_column]
      class_name = mapped_attributes[class_column]
      data_source_id = source_record.data_source_id

      if source_value.blank? || class_name.blank?
        mapped_attributes[target_column] = nil
        return
      end

      lookup_field = lookup_field_mappings[class_name]
      if lookup_field.blank?
        Rails.logger.warn "No lookup field mapping found for class: #{class_name}"
        mapped_attributes[target_column] = nil
        return
      end

      if lookup_cache
        # Use cache for batch processing
        cache_key = [class_name, data_source_id, lookup_field, source_value]
        database_id = lookup_cache[cache_key]

        if database_id.nil? && !lookup_cache.key?(cache_key)
          # Cache miss - this shouldn't happen in proper batch processing
          Rails.logger.warn "Cache miss during record lookup: #{cache_key}"
          database_id = perform_individual_lookup(class_name, lookup_field, source_value, data_source_id)
          lookup_cache[cache_key] = database_id
        end
      else
        # Individual lookup (less efficient)
        database_id = perform_individual_lookup(class_name, lookup_field, source_value, data_source_id)
      end

      if database_id
        mapped_attributes[target_column] = database_id
      else
        Rails.logger.warn "Record lookup failed: #{class_name} with #{lookup_field}=#{source_value} not found"
        mapped_attributes[target_column] = nil
      end
    end

    # Performs an individual record lookup (used when no cache is available)
    #
    # @param class_name [String] The target class name to search
    # @param lookup_field [String] The field name to search by
    # @param source_value [String] The value to search for
    # @param data_source_id [Integer, nil] Optional data source ID to scope the search
    # @return [Integer, nil] The database ID if found, nil otherwise
    # @private
    private_class_method def self.perform_individual_lookup(class_name, lookup_field, source_value, data_source_id)
      klass = class_name.constantize
      query = klass.where(lookup_field => source_value)
      query = query.where(data_source_id: data_source_id) if data_source_id && klass.column_names.include?('data_source_id')
      query.pick(:id)
    rescue StandardError => e
      Rails.logger.error "Error during individual record lookup for #{class_name}: #{e.message}"
      nil
    end
  end
end
