###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvTwentyTwentySix
  # Encapsulates the definition and logic for a single custom file configuration
  class CustomFileDefinition
    attr_reader :config_data

    def initialize(config_hash)
      @config_data = config_hash.freeze
    end

    # Basic file properties
    def filename
      @config_data['filename']
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

    # Warehouse-related properties
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

    # Augmentation properties
    def augments_warehouse_table
      @config_data['augments_warehouse_table']
    end

    def augment_key
      @config_data['augment_key']
    end

    def augment_import_class
      @config_data['augment_import_class']
    end

    def augments?
      augments_warehouse_table.present?
    end

    def augment_import_klass
      return nil unless augments?
      return augment_import_class.constantize if augment_import_class.present?

      nil
    end

    # Column-related properties
    def columns
      @config_data['columns'] || []
    end

    def column_names
      columns.map { |col| col['name'] }
    end

    def required_columns
      columns.select { |col| col['required'] == true }
    end

    # Returns the key to use for HUD operations (augment_key, warehouse_key, or first column name)
    def hud_key
      augment_key || warehouse_key || columns.first&.dig('name')
    end

    # Warehouse column mappings
    def warehouse_target_columns
      columns.map do |col|
        mapping = col['warehouse_column_mapping'] || {}
        mapping['target_column'] || col['name']
      end
    end

    def upsert_column_names
      excluded_augmentation_columns = ['DateCreated', 'DateUpdated', 'DateDeleted', 'ExportID', 'UserID']
      excluded_columns = augments? ? excluded_augmentation_columns : ['DateCreated', 'DateUpdated', 'DateDeleted', 'ExportID']

      (warehouse_target_columns - excluded_columns).map(&:to_sym)
    end

    def create_columns
      warehouse_target_columns - [
        'DateCreated',
        'DateUpdated',
        'DateDeleted',
        'ExportID',
      ]
    end

    # Backwards compatibility - returns the raw hash
    def to_h
      @config_data
    end

    def ==(other)
      other.is_a?(self.class) && config_data == other.config_data
    end

    def hash
      config_data.hash
    end
  end
end
