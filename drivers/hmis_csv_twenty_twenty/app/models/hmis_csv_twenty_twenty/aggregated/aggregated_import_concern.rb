###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HmisCsvTwentyTwenty::Aggregated::AggregatedImportConcern
  extend ActiveSupport::Concern

  included do
    def find_matching_record
      self.class.find_by(self.class.hud_key => self[self.class.hud_key], data_source_id: data_source_id)
    end

    def newer_than?(matching_record)
      false unless matching_record.DateUpdated >= self.DateUpdated

      source_hash != matching_record.source_hash
    end

    def self.import(batch)
      updated_batch = []
      batch.each do |incoming|
        existing = incoming.find_matching_record
        if existing.present?
          updated_batch << incoming if incoming.newer_than?(existing)
        else
          updated_batch << incoming
        end
      end
      super(updated_batch, on_duplicate_key_update: {
        conflict_target: conflict_target,
        columns: upsert_column_names(version: '2020'),
      })
    end
  end
end
