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
      klass = self.class.reflect_on_association(:destination_record).klass
      # Fetch pre-computed attributes from the cache, defaulting to an empty hash
      cache = self.class._mapped_attributes_cache || {}
      mapped_attributes = cache[send(hud_key)] || {}

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
    # Manually define accessors for a class instance variable to ensure it's
    # defined on the including class, not the concern itself.
    def _mapped_attributes_cache
      @_mapped_attributes_cache
    end

    def _mapped_attributes_cache=(cache)
      @_mapped_attributes_cache = cache
    end

    # Pre-compute all column mappings for a custom file, caching the result for use in as_destination_record
    def cache_mapped_attributes(importer_log_id:)
      # 1. Get all records that will be imported for this run
      records_to_process = where(importer_log_id: importer_log_id)

      # 2. Instantiate a mapper and batch-process all records at once, populating the cache
      mapper = HmisCsvTwentyTwentySix::Importer::Custom::ColumnMapper.new(custom_file_definition.columns)
      self._mapped_attributes_cache = {}
      records_to_process.find_in_batches(batch_size: 10_000) do |batch|
        _mapped_attributes_cache.merge!(mapper.map_batch(batch))
      end
    end

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
      # Delegate to the augment_import_klass if this is an augmentation, otherwise return self
      custom_file_definition.augment_import_klass || self
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

    def custom_file?
      true
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
  end

  # The included block and its `as_destination_record` method remain the same,
  # but they will now be able to pull efficiently from the pre-populated cache.
end
