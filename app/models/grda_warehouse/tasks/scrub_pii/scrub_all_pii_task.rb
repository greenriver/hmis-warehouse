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
  # * Requires confirm_databases: naming every database the scrubbed models and their version tables live in
  class ScrubAllPiiTask
    def self.perform(...)
      new.perform(...)
    end

    def perform(confirm_databases:, **scrubber_opts)
      expected = expected_databases
      raise ArgumentError, "confirm_databases must equal #{expected.inspect}" unless Array(confirm_databases).sort == expected

      with_lock do
        total = 0
        scrubber = Pii::Scrubber::ScrubModelPii.new(**scrubber_opts)
        version_pruner = Pii::Scrubber::VersionHistoryPruner.new
        # Versions go first so a scrub failure still leaves no history behind
        Pii::Scrubber::ScrubbableModels.all.each do |model|
          version_pruner.perform(owner: model)
        end
        Pii::Scrubber::ScrubbableModels.to_scrub.each do |model|
          total += scrubber.perform(model.unscoped)
        end
        total
      end
    end

    # The sorted database names an operator must pass as confirm_databases
    def expected_databases
      models = Pii::Scrubber::ScrubbableModels.all
      databases = models.map { |model| model.connection.current_database }
      # The pruner deletes from each paper-trail model's version table, which can live in another database
      pruner = Pii::Scrubber::VersionHistoryPruner.new
      databases += models.filter_map { |model| pruner.version_class(model)&.connection&.current_database }
      (databases << GrdaWarehouseBase.connection.current_database).uniq.sort
    end

    protected

    def with_lock(&block)
      lock_name = self.class.name.demodulize
      GrdaWarehouseBase.with_advisory_lock(lock_name, timeout_seconds: 0, &block)
    end
  end
end
