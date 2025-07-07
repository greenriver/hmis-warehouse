###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvTwentyTwentySix::Importer
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
    # Applies column mappings from source record to target attributes
    #
    # @param source_record [Object] Source record with data to map
    # @param mapped_attributes [Hash] Hash to store mapped attributes
    # @param column_configs [Array<Hash>] Array of column configurations from YAML
    # @return [void]
    def self.apply_mappings(source_record, mapped_attributes, column_configs)
      column_configs.each do |column_config|
        next unless column_config['warehouse_column_mapping']

        column_name = column_config['name']
        value = source_record[column_name]
        mapping_config = column_config['warehouse_column_mapping']

        case mapping_config['type']
        when 'direct'
          apply_direct_mapping(mapped_attributes, value, mapping_config)
        when 'value_based_multi_column'
          apply_value_based_multi_column_mapping(mapped_attributes, value, mapping_config)
        when 'concatenation'
          apply_concatenation_mapping(mapped_attributes, value, mapping_config)
        else
          Rails.logger.warn "Unknown mapping type: #{mapping_config['type']}"
        end
      end
    end

    # Handle key-value store processing for CustomDataElements
    #
    # CustomDataElements work differently - they reference definitions and store
    # arbitrary key-value pairs that get converted to typed values based on the
    # field definitions.
    #
    # @param source_records [ActiveRecord::Relation] Records to process
    # @param file_config [Hash] Configuration for the custom data element file
    # @param importer_log [Object] Current import log for scoping
    # @return [void]
    def self.process_key_value_store(source_records, file_config, importer_log)
      return unless file_config['key_value_store']

      definition_class_name = "HmisCsvTwentyTwentySix::Importer::#{file_config['definition_class']}"
      definition_class = definition_class_name.constantize
      definition_key = file_config['definition_key']

      # Load all definitions for this import
      definitions = definition_class.where(importer_log_id: importer_log.id).
        index_by(&definition_key.to_sym)

      # Process each data element
      source_records.find_each do |record|
        definition_id = record[definition_key]
        definition = definitions[definition_id]

        unless definition
          Rails.logger.warn "CustomDataElement references unknown definition: #{definition_id}"
          next
        end

        # Apply key-value processing based on definition
        process_custom_data_element(record, definition)
      end
    end

    # Processes a single custom data element and creates/updates the warehouse record
    #
    # This method handles the special case of CustomDataElements which are key-value
    # pairs that reference definitions. The definition contains the field type which
    # determines how the value should be converted and stored.
    #
    # @param data_element [Object] The importer record containing the data element
    # @param definition [Object] The definition record that describes this data element
    # @return [void]
    # @raise [ActiveRecord::RecordInvalid] If the warehouse record cannot be saved
    # @private
    private_class_method def self.process_custom_data_element(data_element, definition)
      # Create or update the warehouse record
      warehouse_class = data_element.class.warehouse_class

      warehouse_record = warehouse_class.find_or_initialize_by(
        data_source_id: data_element.data_source_id,
        CustomDataElementID: data_element.CustomDataElementID,
      )

      # FIXME: do we need this?  Config should be enough
      # Map standard fields
      warehouse_record.assign_attributes(
        CustomDataElementDefinitionID: data_element.CustomDataElementDefinitionID,
        RecordType: data_element.RecordType,
        RecordID: data_element.RecordID,
        Value: convert_value_by_type(data_element.Value, definition.FieldType),
        DataCollectionStage: data_element.DataCollectionStage,
        InformationDate: data_element.InformationDate,
        UserID: data_element.UserID,
        DateCreated: data_element.DateCreated,
        DateUpdated: data_element.DateUpdated,
        DateDeleted: data_element.DateDeleted,
        ExportID: data_element.ExportID,
      )

      # FIXME: this should happen in a batch
      warehouse_record.save!
    end

    # Converts a string value to the appropriate type based on field definition
    #
    # This method handles type conversion for CustomDataElements where the value
    # is stored as a string in the CSV but needs to be converted to the proper
    # type based on the field definition.
    #
    # @param value [String, nil] The string value to convert
    # @param field_type [String, nil] The target field type from the definition
    # @return [Object, nil] The converted value or nil if conversion fails
    #
    # @example Converting different types
    #   convert_value_by_type("42", "integer")     # => 42
    #   convert_value_by_type("true", "boolean")   # => true
    #   convert_value_by_type("2023-01-01", "date") # => Date.new(2023, 1, 1)
    #   convert_value_by_type("hello", "string")   # => "hello"
    #
    # @private
    private_class_method def self.convert_value_by_type(value, field_type)
      return nil if value.blank?

      case field_type&.downcase
      when 'integer'
        value.to_i
      when 'boolean'
        ['true', '1', 'yes', 'y'].include?(value.to_s.downcase)
      when 'date'
        begin
          Date.parse(value)
        rescue StandardError
          nil
        end
      else
        value.to_s
      end
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
  end
end
