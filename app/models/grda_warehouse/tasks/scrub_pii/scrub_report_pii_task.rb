###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'progress_bar'
module GrdaWarehouse::Tasks::ScrubPii
  # Responsible for removing or obfuscating personally identifiable information (PII) from report records.
  class ScrubReportPiiTask
    attr_accessor :strategy

    def self.perform(...)
      new.perform(...)
    end

    STRATEGIES = {
      null: NullStrategy,
      fake: FakeStrategy,
      identifier: IdentifierStrategy,
    }.freeze

    def perform(strategy: :null, prng_seed: nil, progress: false)
      with_lock do
        Faker::Config.random = Random.new(prng_seed) if prng_seed
        raise ArgumentError, "unknown strategy #{strategy}" unless STRATEGIES.key?(strategy)

        @strategy = STRATEGIES[strategy].new

        total = models.map(&:count).sum
        progress_bar = ProgressBar.new(total, :counter, :bar, :percentage, :rate, :eta) if progress
        models.each do |model|
          process_model(model, progress_bar)
        end
      end
    end

    protected

    def models
      [
        HudApr::Fy2020::AprClient,
        HapReport::HapClient,
        HomelessSummaryReport::Client,
        HudDataQualityReport::Fy2020::DqClient,
        HudPathReport::Fy2020::PathClient,
        HudSpmReport::Fy2020::SpmClient,
        IncomeBenefitsReport::Client,
        MaYyaReport::Client,
      ]
    end

    def process_model(model, progress)
      model.unscoped.find_in_batches do |batch|
        # one transaction per batch
        GrdaWarehouse::Hud::Client.transaction do
          values = batch.map do |record|
            strategy.report_client_attrs(record)
          end
          import!(model, values)
          progress&.increment!(batch.size)
        end
      end
    end

    def import!(klass, values)
      return if values.blank?

      result = klass.import(values, on_duplicate_key_update: { conflict_target: [:id], columns: values.first.keys }, validate: false)
      raise if result.failed_instances.any?
    end

    def with_lock(&block)
      lock_name = self.class.name.demodulize
      GrdaWarehouseBase.with_advisory_lock(lock_name, timeout_seconds: 0, &block)
    end
  end
end
