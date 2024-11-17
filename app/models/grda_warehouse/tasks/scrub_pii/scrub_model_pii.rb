###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'progress_bar'

module GrdaWarehouse::Tasks::ScrubPii
  # Scrub personally identifiable information (PII) from the given scope
  # usage:
  #   scrubber = GrdaWarehouse::Tasks::ScrubPii::ScrubModelPii.new(variant: :fake, progress: true)
  #   scrubber.perform(Hmis::Hud::Client.all)
  class ScrubModelPii
    def initialize(variant: nil, progress: false)
      @progress = progress
      @scrubbers = [
        custom_scrubber(variant), # custom handling for names (identifier, faker, etc)
        GrdaWarehouse::Tasks::ScrubPii::DobScrubber.new, # special handling for dob/age
        GrdaWarehouse::Tasks::ScrubPii::DefaultScrubber.new, # catch-all, handles fields not yet consumed
      ].compact
    end

    def perform(scope)
      model = scope.klass
      raise "#{model.name} is missing pii attribute configuration" unless model.stores_pii?

      bar = new_progress_bar(models) if @progress
      bar.puts model.name if @progress
      process_model(model, scope, bar)
    end

    protected

    def process_model(model, scope, progress)
      non_nullable_cols = model.columns.reject(&:null).map { |c| c.name.to_sym }
      scope.find_in_batches do |batch|
        values = batch.map do |record|
          pii_fields = PiiAttribute.from_record(record)
          @scrubbers.each do |scrubber|
            scrubber.perform(pii_fields)
          end
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

    def custom_scrubber(name)
      case name
      when :static
        GrdaWarehouse::Tasks::ScrubPii::IdentifierScrubber.new
      when :fake
        GrdaWarehouse::Tasks::ScrubPii::FakeScrubber.new
      when nil
        nil
      else
        raise ArgumentError, "unknown scrubber #{name}"
      end
    end

    def import!(klass, values)
      return if values.blank?

      result = klass.import(values, on_duplicate_key_update: { conflict_target: [:id], columns: values.first.keys }, validate: false)
      raise if result.failed_instances.any?
    end

    def new_progress_bar(models)
      total = models.map(&:count).sum
      ProgressBar.new(total, :counter, :bar, :percentage, :rate, :eta) if progress
    end
  end
end
