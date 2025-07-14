###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvTwentyTwentySix::Importer::Custom::CustomImportConcern
  extend ActiveSupport::Concern
  include HmisCsvTwentyTwentySix::CustomModelConfig

  included do
    def as_destination_record
      config = self.class.custom_file_config

      raise 'Unknown custom import type' unless config['augments_warehouse_table'].present?

      config = self.class.custom_file_config
      klass = self.class.reflect_on_association(:destination_record).klass

      # Apply all column mappings using the generic mapper
      mapped_attributes = {}
      HmisCsvTwentyTwentySix::Importer::ColumnMapper.apply_mappings(
        self,
        mapped_attributes,
        config['columns'],
      )

      record = klass.new(mapped_attributes)

      # We explicitly don't update the source hash since that would cause future
      # imports to the augmented class to appear modified
      # We also don't set the source_id as it would cause the source data drill-down
      # to break
      # record.source_hash = source_hash
      # # Note which record we're sending this from for error checking
      # record.source_id = id

      record
    end
  end

  class_methods do
    def upsert_column_names(version: hud_csv_version) # rubocop:disable Lint/UnusedMethodArgument
      # Return all HMIS data columns
      # Remove DateCreated, DateUpdated, DateDeleted, ExportID, UserID if this is an augmentation
      # Note: version parameter is required by ImportConcern interface but not used
      # for custom files since structure comes from YAML configuration
      excluded_augmentation_columns = ['DateCreated', 'DateUpdated', 'DateDeleted', 'ExportID', 'UserID']
      hmis_columns = custom_file_config['columns'].map { |col| col['name'] }

      excluded_columns = augments? ? excluded_augmentation_columns : []
      (hmis_columns - excluded_columns).map(&:to_sym)
    end

    # Augmented data should never return new data since it should only update existing records
    def incoming_data(importer_log_id:)
      return none if augments?

      where(importer_log_id: importer_log_id).should_import
    end

    # Augmented data should never delete records since it should only update existing records
    def pending_deletions(data_source_id:, project_ids:, date_range:)
      return none if augments?

      involved_warehouse_scope(
        data_source_id: data_source_id,
        project_ids: project_ids,
        date_range: date_range,
      ).delete_pending
    end

    def custom_import_class
      warehouse_class
    end

    def warehouse_class
      config = custom_file_config
      if config['augments_warehouse_table']
        config['augments_warehouse_table'].constantize
      elsif config['creates_warehouse_table']
        config['warehouse_class_name'].constantize
      else
        super
      end
    end

    def create_columns
      config = custom_file_config

      config['columns'].map(&:name) - [
        'DateCreated',
        'DateUpdated',
        'DateDeleted',
        'ExportID',
      ]
    end

    # Delegate to the class we are augmenting
    def involved_warehouse_scope(data_source_id:, project_ids:, date_range:)
      config = custom_file_config

      # At this time, we only support augmentations
      raise 'Unknown custom import type' unless augments? && config['augment_import_class'].present?

      augment_import_class = config['augment_import_class'].constantize
      augment_import_class.involved_warehouse_scope(data_source_id: data_source_id, project_ids: project_ids, date_range: date_range)
    end

    # Prevent deletions for augmentation classes since we only want to update existing records
    def prevent_import_deletions?
      augments?
    end

    # Delegate to the class we are augmenting
    def existing_data(data_source_id:, project_ids:, date_range:)
      config = custom_file_config

      # At this time, we only support augmentations
      raise 'Unknown custom import type' unless augments? && config['augment_import_class'].present?

      augment_import_class = config['augment_import_class'].constantize
      augment_import_class.existing_data(data_source_id: data_source_id, project_ids: project_ids, date_range: date_range)
    end

    # Delegate to the class we are augmenting
    def existing_destination_data(data_source_id:, project_ids:, date_range:)
      config = custom_file_config

      # At this time, we only support augmentations
      raise 'Unknown custom import type' unless augments? && config['augment_import_class'].present?

      augment_import_class = config['augment_import_class'].constantize
      augment_import_class.involved_warehouse_scope(
        data_source_id: data_source_id,
        project_ids: project_ids,
        date_range: date_range,
      ).with_deleted
    end

    def augments?
      custom_file_config['augments_warehouse_table'].present?
    end
  end
end
