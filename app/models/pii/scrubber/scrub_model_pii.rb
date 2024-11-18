###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'progress_bar'

module Pii::Scrubber
  # Scrub personally identifiable information (PII) from the given scope
  # usage:
  #   scrubber = ScrubModelPii.new(progress: true)
  #   scrubber.perform(Hmis::Hud::Client.all)
  class ScrubModelPii
    attr_accessor :custom_scrubber
    def initialize(progress: false, custom_scrubber: nil)
      @progress = progress

      self.custom_scrubber = lookup_custom_scrubber(custom_scrubber)
    end

    def perform(scope)
      model = scope.klass
      raise "#{model.name} is missing pii attribute configuration" unless model.stores_pii?

      bar = new_progress_bar(scope) if @progress
      bar.puts model.name if @progress
      without_optimistic_locking(model) do
        process_model(model, scope, bar)
      end
    end

    protected

    def process_model(model, scope, progress)
      non_nullable_cols = model.columns.reject(&:null).map { |c| c.name.to_sym }
      scope.find_in_batches do |batch|
        values = batch.map do |record|
          pii_fields = Pii::Scrubber::PiiAttribute.from_record(record)

          # custom scrubbing if provided (fake values)
          custom_scrubber&.perform(pii_fields)

          # handle dob and age fields
          dob_scrubber.perform(pii_fields.reject(&:scrubbed?))

          # scrub remaining sensitive fields
          basic_scrubber.perform(pii_fields.filter { |f| f.sensitive? && !f.scrubbed? })

          pii_attrs = pii_fields.
            filter(&:scrubbed?).
            to_h { |f| [f.name, f.scrubbed_value] }

          # include non-nullable attrs to ensure upsert works in postgres
          required_attrs = non_nullable_cols.to_h do |column|
            [column, record.send(column)]
          end

          pii_attrs.merge(required_attrs)
        end
        import!(model, values)
        progress&.increment!(batch.size)
      end
    end

    # special handling for dob/age
    def dob_scrubber
      @dob_scrubber || Pii::Scrubber::DobScrubber.new
    end

    # catch-all scrubber
    def basic_scrubber
      @basic_scrubber ||= Pii::Scrubber::BasicScrubber.new
    end

    def lookup_custom_scrubber(name)
      case name
      when :fake
        Pii::Scrubber::FakeScrubber.new
      when :static
        Pii::Scrubber::StaticScrubber.new
      when nil
        nil
      else
        raise "unknown scrubber '#{name}'"
      end
    end

    def import!(klass, values)
      return if values.blank?

      result = klass.import(values, on_duplicate_key_update: { conflict_target: [:id], columns: values.first.keys }, validate: false)
      raise if result.failed_instances.any?
    end

    def without_optimistic_locking(model)
      prev = model.lock_optimistically
      model.lock_optimistically = false
      begin
        yield
      ensure
        model.lock_optimistically = prev
      end
    end

    def new_progress_bar(scope)
      total = scope.count
      ProgressBar.new(total, :counter, :bar, :percentage, :rate, :eta)
    end
  end
end
