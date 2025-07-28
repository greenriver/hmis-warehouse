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
      definition = self.class.custom_file_definition
      klass = self.class.reflect_on_association(:destination_record).klass

      # Apply all column mappings using the generic mapper
      mapped_attributes = {}
      HmisCsvTwentyTwentySix::Importer::Custom::ColumnMapper.apply_mappings(
        self,
        mapped_attributes,
        definition.columns,
      )

      record = klass.new(mapped_attributes)

      # For augmentations, we explicitly don't update the source hash since that would cause future
      # imports to the augmented class to appear modified
      # We also don't set the source_id as it would cause the source data drill-down to break
      return record if self.class.augments?

      record.source_hash = source_hash
      # Note which record we're sending this from for error checking
      record.source_id = id
      # For non-augmentations, we need to set the data_source_id
      record.data_source_id = data_source_id

      record
    end
  end

  class_methods do
    def upsert_column_names(version: hud_csv_version) # rubocop:disable Lint/UnusedMethodArgument
      custom_file_definition.upsert_column_names
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
      custom_file_definition.warehouse_class
    end

    def create_columns
      custom_file_definition.create_columns
    end

    # Delegate to the class we are augmenting
    def involved_warehouse_scope(data_source_id:, project_ids:, date_range:)
      return import_klass.involved_warehouse_scope(data_source_id: data_source_id, project_ids: project_ids, date_range: date_range) if augments?

      # NOTE: when importing custom files that aren't directly associated with a project,
      # we require all rows be sent every time as we don't have a way to scope a "report scope"
      # TODO: this should probably have some logic about if it references an enrollment or project, then further limit the scope
      warehouse_class.importable.where(data_source_id: data_source_id)
    end

    def import_klass
      return custom_file_config['augment_import_class'].constantize if augments?

      self
    end

    # Prevent deletions for augmentation classes since we only want to update existing records
    def prevent_import_deletions?
      augments?
    end

    # Delegate to the class we are augmenting
    def existing_data(data_source_id:, project_ids:, date_range:)
      return import_klass.existing_data(data_source_id: data_source_id, project_ids: project_ids, date_range: date_range) if augments?

      # NOTE: when importing custom files that aren't directly associated with a project,
      # we require all rows be sent every time as we don't have a way to scope a "report scope"
      existing_scope = involved_warehouse_scope(
        data_source_id: data_source_id,
        project_ids: project_ids,
        date_range: date_range,
      )
      existing_scope = existing_scope.with_deleted if paranoid?
      existing_scope
    end

    # Delegate to the class we are augmenting
    def existing_destination_data(data_source_id:, project_ids:, date_range:)
      if augments?
        import_klass.involved_warehouse_scope(
          data_source_id: data_source_id,
          project_ids: project_ids,
          date_range: date_range,
        ).with_deleted
      else
        super
      end
    end

    def augments?
      custom_file_definition.augments?
    end

    # New method to get the definition object
    def custom_file_definition
      @custom_file_definition ||= HmisCsvTwentyTwentySix.custom_files_config.find_definition(
        "#{name.demodulize.underscore.camelize}.csv",
      )
    end

    # Keep backwards compatibility
    def custom_file_config
      custom_file_definition.to_h
    end
  end
end
