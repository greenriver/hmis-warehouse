###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvImporter::Aggregated::AggregatedImportConcern
  extend ActiveSupport::Concern

  included do
    def newer_than_and_changed?(existing)
      return false if self.DateUpdated < existing.DateUpdated

      source_hash != existing.source_hash
    end

    def self.upsert?
      true
    end

    def self.new_from(source)
      source_data = source.attributes.slice(*source.class.create_columns)
      new(
        source_data.merge(
          source_type: source.class.name,
          source_id: source.id,
          data_source_id: source.data_source_id,
          importer_log_id: source.importer_log_id,
          pre_processed_at: source.pre_processed_at,
          source_hash: source.source_hash,
        ),
      )
    end

    def self.import_aggregated(batch)
      updated_batch = []
      existing_records = find_matching_records(batch)
      batch.each do |incoming|
        existing = existing_records[incoming[hud_key]]
        if existing.present?
          updated_batch << incoming if incoming.newer_than_and_changed?(existing)
        else
          updated_batch << incoming
        end
      end
      import(
        updated_batch,
        on_duplicate_key_update: {
          conflict_target: conflict_target,
          columns: upsert_column_names - [:pending_date_deleted],
        },
      )
    end

    def self.find_matching_records(batch)
      data_source_id = batch.first&.data_source_id # All of the records in an aggregation are in the same data source
      keys = batch.map(&hud_key.to_sym)
      where(hud_key => keys, data_source_id: data_source_id).index_by(&hud_key.to_sym)
    end
  end
end
