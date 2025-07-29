###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvTwentyTwentySix::Importer::Custom
  # A service object that handles column mapping from custom CSV files to warehouse tables.
  #
  # This class is instantiated with a set of mapping rules (derived from a
  # custom file's YAML configuration) and provides methods to transform
  # source records into the appropriate warehouse format. It supports:
  #
  # 1.  **Direct mapping**: Simple 1:1 column mapping.
  # 2.  **Value-based multi-column mapping**: Maps source values to different target columns.
  # 3.  **Concatenation mapping**: Combines multiple source values into one target column.
  # 4.  **Value mapping**: Transforms source values based on a lookup table.
  # 5.  **Record lookup**: Efficiently looks up foreign keys in other warehouse tables.
  # 6.  **Static value**: Assigns a fixed value to a target column.
  #
  # == Usage Pattern
  #
  # The ColumnMapper is instantiated with the column configurations from a
  # CustomFileDefinition. The resulting object can then be used to map one or
  # many records.
  #
  #   # 1. Get the definition for the custom file
  #   definition = HmisCsvTwentyTwentySix.custom_files_config.find_definition('MyFile.csv')
  #
  #   # 2. Create a mapper instance with the column rules
  #   mapper = HmisCsvTwentyTwentySix::Importer::Custom::ColumnMapper.new(definition.columns)
  #
  #   # 3. Map a single source record
  #   mapped_attributes = mapper.map(source_record)
  #
  #   # 4. Or, map a batch of records efficiently
  #   all_mapped_attributes = mapper.map_batch(source_records)
  #
  # == Mapping Configuration Examples
  #
  # @example Direct mapping (1:1 column mapping)
  #   # warehouse_column_mapping:
  #   #   type: "direct"
  #   #   target_column: "Woman"
  #
  # @example Value-based multi-column mapping (coded values to multiple columns)
  #   # warehouse_column_mapping:
  #   #   type: "value_based_multi_column"
  #   #   value_mappings:
  #   #     - { condition: { value: "1" }, target_column: "Woman", target_value: 1 }
  #   #     - { condition: { value: "2" }, target_column: "Man",   target_value: 1 }
  #
  # @example Record Lookup Mapping
  #   # warehouse_column_mapping:
  #   #   type: "record_lookup"
  #   #   class_column: "owner_type"
  #   #   target_column: "owner_id"
  #   #   lookup_field_mappings:
  #   #     "GrdaWarehouse::Hud::Client": "PersonalID"
  #   #     "GrdaWarehouse::Hud::Enrollment": "EnrollmentID"
  #
  # == Error Handling
  #
  # The mapper handles various error conditions gracefully:
  # - Unknown mapping types are logged as warnings.
  # - Failed record lookups are logged and result in a nil value.
  # - Invalid data conversions return nil or default values.
  #
  # @see CustomImportConcern For integration with importer classes.
  # @see CustomFileDefinition For the source of the column configurations.
  class ColumnMapper
    def initialize(column_configs)
      @column_configs = column_configs
      @record_lookup_configs = @column_configs.select { |col| col.dig('warehouse_column_mapping', 'type') == 'record_lookup' }
    end

    # Applies all configured column mappings for a single source record.
    #
    # @param source_record [Object] Source record with data to map
    # @return [Hash] A hash containing the mapped attributes
    def map(source_record)
      return {} if source_record.blank?

      hud_key = source_record.hud_key
      map_batch([source_record])[source_record[hud_key.to_s]] || {}
    end

    # Applies column mappings from source records to target attributes with efficient record lookup support
    #
    # @param source_records [Array<Object>] Array of source records to process
    # @return [Array<Hash>] Array of mapped attributes for each record
    def map_batch(source_records)
      return {} if source_records.empty?

      hud_key = source_records.first.hud_key
      # Phase 1: Apply all standard mappings
      results = source_records.map do |source_record|
        mapped_attributes = {}
        apply_standard_mappings(source_record, mapped_attributes)
        { source_record: source_record, mapped_attributes: mapped_attributes }
      end

      # Phase 2: Handle record lookups in batches
      apply_record_lookups_batch(results)
      results.map { |result| [result[:source_record][hud_key.to_s], result[:mapped_attributes]] }.to_h
    end

    # Applies all standard (non-record-lookup) mappings
    #
    # @param source_record [Object] Source record with data to map
    # @param mapped_attributes [Hash] Hash to store mapped attributes
    # @return [void]
    private def apply_standard_mappings(source_record, mapped_attributes)
      @column_configs.each do |column_config|
        column_name = column_config['name']
        value = source_record[column_name]

        # Default to direct mapping with same column name if no mapping specified
        mapping_config = column_config['warehouse_column_mapping'] || {}
        mapping_config = apply_mapping_defaults(mapping_config, column_name)

        case mapping_config['type']
        when 'direct'
          apply_direct_mapping(mapped_attributes, value, mapping_config, column_config)
        when 'value_based_multi_column'
          apply_value_based_multi_column_mapping(mapped_attributes, value, mapping_config)
        when 'concatenation'
          apply_concatenation_mapping(mapped_attributes, value, mapping_config)
        when 'value_mapping'
          apply_value_mapping(mapped_attributes, value, mapping_config, column_config)
        when 'record_lookup'
          # Skip record lookups in phase 1 - they'll be handled in batch in phase 2
          next
        when 'static_value'
          apply_static_value_mapping(mapped_attributes, mapping_config, column_config)
        else
          Rails.logger.warn "Unknown mapping type: #{mapping_config['type']}"
        end
      end
    end

    # Applies record lookup mappings in batches for performance
    #
    # @param results [Array<Hash>] Array of { source_record:, mapped_attributes: } hashes
    # @return [void]
    private def apply_record_lookups_batch(results)
      return if @record_lookup_configs.empty?

      # Collect all lookups needed
      lookups_by_class = {}

      @record_lookup_configs.each do |column_config|
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
    private def apply_batch_lookup(lookup_info, results)
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
    # @param mapping_config [Hash] The mapping configuration (may be empty)
    # @param column_name [String] The source column name
    # @return [Hash] The mapping configuration with defaults applied
    private def apply_mapping_defaults(mapping_config, column_name)
      mapping_config = mapping_config.dup
      mapping_config['type'] ||= 'direct'
      mapping_config['target_column'] ||= column_name
      mapping_config
    end

    # Applies direct column mapping from source to target
    #
    # @param mapped_attributes [Hash] Hash to store the mapped attributes
    # @param value [Object] The source value to map
    # @param mapping_config [Hash] Configuration containing the target column
    # @return [void]
    private def apply_direct_mapping(mapped_attributes, value, mapping_config, column_config)
      mapped_attributes[mapping_config['target_column']] = cast_value(value, column_config['type'])
    end

    # Applies value-based multi-column mapping
    #
    # @param mapped_attributes [Hash] Hash to store the mapped attributes
    # @param value [Object] The source value to evaluate
    # @param mapping_config [Hash] Configuration containing the mapping rules
    # @return [void]
    private def apply_value_based_multi_column_mapping(mapped_attributes, value, mapping_config)
      mapping_config['value_mappings'].each do |mapping|
        mapped_attributes[mapping['target_column']] = mapping['target_value'] if mapping['condition']['value'] == value
      end
    end

    # Applies concatenation mapping to combine multiple values
    #
    # @param mapped_attributes [Hash] Hash to store the mapped attributes
    # @param value [Object] The source value to concatenate
    # @param mapping_config [Hash] Configuration containing target column and separator
    # @return [void]
    private def apply_concatenation_mapping(mapped_attributes, value, mapping_config)
      existing_value = mapped_attributes[mapping_config['target_column']] || ''
      separator = mapping_config['separator'] || ' '
      mapped_attributes[mapping_config['target_column']] = [existing_value, value].reject(&:blank?).join(separator)
    end

    # Applies value mapping based on configuration.
    #
    # @param mapped_attributes [Hash] Hash to store the mapped attributes
    # @param value [Object] The source value to transform
    # @param mapping_config [Hash] Configuration containing the mapping rules
    # @return [void]
    private def apply_value_mapping(mapped_attributes, value, mapping_config, column_config)
      target_column = mapping_config['target_column']
      value_mappings = mapping_config['value_mappings']

      # Use the mapped value if it exists, otherwise use the original value
      transformed_value = value_mappings[value] || value
      mapped_attributes[target_column] = cast_value(transformed_value, column_config['type'])
    end

    # Applies static value mapping from source to target
    #
    # @param mapped_attributes [Hash] Hash to store the mapped attributes
    # @param mapping_config [Hash] Configuration containing the target column and value
    # @return [void]
    private def apply_static_value_mapping(mapped_attributes, mapping_config, column_config)
      mapped_attributes[mapping_config['target_column']] = cast_value(mapping_config['value'], column_config['type'])
    end

    # Casts a value to the specified type.
    # @param value [Object] The value to cast.
    # @param type [String] The target type (e.g., 'integer', 'string').
    # @return [Object] The casted value.
    private def cast_value(value, type)
      # Preserve boolean false, since `false.blank?` is true.
      return value if value == false
      return nil if value.blank?

      case type
      when 'integer'
        value.to_i
      else # Default to string or no-op
        value
      end
    end
  end
end
