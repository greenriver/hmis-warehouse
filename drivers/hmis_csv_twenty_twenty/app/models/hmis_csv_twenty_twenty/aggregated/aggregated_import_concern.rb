###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HmisCsvTwentyTwenty::Aggregated::AggregatedImportConcern
  extend ActiveSupport::Concern

  included do
    def newer_than?(existing)
      false unless existing.DateUpdated >= self.DateUpdated

      source_hash != existing.source_hash
    end

    def self.import(batch)
      updated_batch = []
      existing_records = find_matching_records(batch)
      batch.each do |incoming|
        existing = existing_records[incoming[hud_key]]
        if existing.present?
          updated_batch << incoming if incoming.newer_than?(existing)
        else
          updated_batch << incoming
        end
      end
      super(
        updated_batch,
        on_duplicate_key_update: {
          conflict_target: conflict_target,
          columns: upsert_column_names(version: '2020'),
        }
      )
    end
  end

  def self.find_matching_records(batch)
    data_source_id = batch.first&.data_source_id # All of the records in an aggregation are in the same data source
    keys = batch.map(&hud_key.to_sym)
    where(hud_key => keys, data_source_id: data_source_id).index_by(&hud_key.to_sym)
  end
end
