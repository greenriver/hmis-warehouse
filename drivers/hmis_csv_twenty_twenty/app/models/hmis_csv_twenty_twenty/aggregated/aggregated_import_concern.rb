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
      batch.each do |record|
        matching_record = record.find_matching_record
        if matching_record.present?
          updated_batch << record if record.newer_than?(matching_record)
        else
          updated_batch << record
        end
      end
      super(updated_batch, on_duplicate_key_update: [hud_key, :data_source_id])
    end
  end
end
