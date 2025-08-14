###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvTwentyTwentySix
  module Custom
    # Encapsulates the definition and logic for a single custom file configuration
    class FileDefinition
      attr_reader :config_data

      SCHEMA_PATH = Rails.root.join('drivers', 'hmis_csv_twenty_twenty_six', 'config', 'custom_file_schema.json').to_s

      def initialize(config_hash)
        errors = HmisExternalApis::JsonValidator.perform({ 'custom_files' => [config_hash] }, SCHEMA_PATH)
        if errors.any?
          error_message = errors.join("\n")
          raise "Invalid custom file configuration for '#{config_hash['filename']}':\n#{error_message}"
        end
        @config_data = config_hash.freeze
      end

      def filename
        @config_data['filename']
      end

      def for_select
        ["#{description} (#{filename})", filename]
      end

      def class_name
        @config_data['class_name']
      end

      def required?
        @config_data['required'] == true
      end

      def description
        @config_data['description']
      end

      def warehouse_key
        @config_data['warehouse_key']
      end

      def warehouse_class_name
        @config_data['warehouse_class_name']
      end

      def warehouse_class
        if augments_warehouse_table.present?
          augments_warehouse_table.constantize
        elsif warehouse_class_name.present?
          warehouse_class_name.constantize
        end
      end

      def augments_warehouse_table
        @config_data['augments_warehouse_table']
      end

      def augment_key
        @config_data['augment_key']
      end

      def augment_import_class
        @config_data['augment_import_class']
      end

      def augments_export_class
        @config_data['augments_export_class']
      end

      def augments?
        augments_warehouse_table.present?
      end

      def augment_import_klass
        return nil unless augments?
        return augment_import_class.constantize if augment_import_class.present?

        nil
      end

      def columns
        @config_data['columns'] || []
      end

      def column_names
        columns.map { |col| col['name'] }
      end

      def required_columns
        columns.select { |col| col['required'] == true }
      end

      def real_columns
        columns.reject { |col| col['type'] == 'virtual' }
      end

      def hud_key
        augment_key || warehouse_key || columns.first&.dig('name')
      end

      def warehouse_target_columns
        columns.map do |col|
          mapping = col['warehouse_column_mapping'] || {}
          mapping['target_column'] || col['name']
        end
      end

      def export_limiting_column_value_mapping
        return unless @config_data['export_limiting_column']

        column = columns.find { |col| col['name'] == @config_data['export_limiting_column'] }
        column.dig('warehouse_column_mapping', 'value_mappings')
      end

      def upsert_column_names
        (warehouse_target_columns - excluded_columns).map(&:to_sym)
      end

      def create_columns
        warehouse_target_columns - always_excluded_columns
      end

      private def excluded_columns
        return always_excluded_columns unless augments?

        always_excluded_columns + ['UserID']
      end

      private def always_excluded_columns
        ['DateCreated', 'DateUpdated', 'DateDeleted', 'ExportID']
      end

      def ==(other)
        other.is_a?(self.class) && config_data == other.config_data
      end
    end
  end
end
