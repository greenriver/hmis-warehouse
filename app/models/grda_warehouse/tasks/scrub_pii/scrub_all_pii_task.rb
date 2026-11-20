###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse::Tasks::ScrubPii
  # Best-effort to scrub personally identifiable information (PII) from all warehouse and reporting tables
  # * Suitable for sanitizing a production database for staging/development use
  # * Delete versions
  class ScrubAllPiiTask
    def self.perform(...)
      new.perform(...)
    end

    def perform(...)
      with_lock do
        total = 0
        scrubber = Pii::Scrubber::ScrubModelPii.new(...)
        version_pruner = Pii::Scrubber::VersionHistoryPruner.new
        Pii::Scrubber::ScrubbableModels.to_scrub.each do |model|
          total += scrubber.perform(model.unscoped)
        end
        Pii::Scrubber::ScrubbableModels.all.each do |model|
          version_pruner.perform(owner: model)
        end
        total
      end
    end

    protected

    def with_lock(&block)
      lock_name = self.class.name.demodulize
      GrdaWarehouseBase.with_advisory_lock(lock_name, timeout_seconds: 0, &block)
    end
  end
end
