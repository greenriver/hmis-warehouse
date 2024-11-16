###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'progress_bar'
module GrdaWarehouse::Tasks::ScrubPii
  # Responsible for removing or obfuscating personally identifiable information (PII) from report records.
  class ScrubReportPiiTask

    def self.perform(...)
      new.perform(...)
    end

    def perform(custom_scrubber: nil, prng_seed: nil, progress: false)
      with_lock do
        Faker::Config.random = Random.new(prng_seed) if prng_seed
        raise ArgumentError, "unknown strategy #{strategy}" unless STRATEGIES.key?(strategy)
        scrubbers = [
          DobScrubber.new(prng_seed),
          custom_scrubber,
          NullScrubber.new,
        ].compact

        total = models.map(&:count).sum
        progress_bar = ProgressBar.new(total, :counter, :bar, :percentage, :rate, :eta) if progress
        models.each do |model|
          process_model(model, scrubbers, progress_bar)
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
        # check for enrollment, "SimpleReports::ReportInstance", anything inheriting from ReportingBase
      ]
    end

    def process_model(model, scrubbers, progress)
      non_nullable_cols = model.columns.reject(&:null).map { |c| c.name.to_sym }
      model.unscoped.find_in_batches do |batch|
        # one transaction per batch
        model.transaction do
          values = batch.map do |record|
            pii_fields = PiiAttribute.from_record(record)
            @scrubbers.each do |scrubber|
              transformer.perform(pii_fields)
            end
            pii_attrs = pii_fields.to_h { |f| [f.name, f.scrubbed_value] }

            required_attrs = non_nullable_cols.to_h do |column|
              [column, record.send(column)]
            end
            pii_attrs.merge(required_attrs)
          end
          import!(model, values)
          progress&.increment!(batch.size)
        end
      end
    end

    protected

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
