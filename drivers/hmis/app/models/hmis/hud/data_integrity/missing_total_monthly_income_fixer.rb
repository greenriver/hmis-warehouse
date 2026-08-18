###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Batch service that fills in TotalMonthlyIncome on IncomeBenefit records that indicate income
# (IncomeFromAnySource = 1) but are missing a total, by summing the individual income source amounts.
#
# Scope-based usage (e.g. in an opt-in ImporterExtension):
#   Hmis::Hud::DataIntegrity::MissingTotalMonthlyIncomeFixer.run!(scope: staging_scope, conflict_target: [:id, :importer_log_id])
#
# Console convenience:
#   Hmis::Hud::DataIntegrity::MissingTotalMonthlyIncomeFixer.for_data_source!(data_source_id: ds_id)
#
class Hmis::Hud::DataIntegrity::MissingTotalMonthlyIncomeFixer
  BATCH_SIZE = 1_000

  # @param scope [ActiveRecord::Relation] the scope of IncomeBenefit(-like) records to process.
  # @param conflict_target [Array<Symbol>] unique key columns for upsert. Defaults to [:id],
  #   but configurable so that callers working with partitioned tables can pass a compound key.
  # @return [Integer] number of records that were updated
  def self.run!(scope:, conflict_target: [:id])
    new(scope: scope, conflict_target: conflict_target).run!
  end

  # Convenience helper: run on all IncomeBenefits in a data source.
  # @param data_source_id [Integer] restrict to IncomeBenefits in this data source.
  # @return [Integer] number of records that were updated
  def self.for_data_source!(data_source_id:)
    run!(scope: Hmis::Hud::IncomeBenefit.where(data_source_id: data_source_id))
  end

  def initialize(scope:, conflict_target: [:id])
    @scope = scope
    @model_class = scope.klass
    @conflict_target = conflict_target
  end

  # @return [Integer] number of records that were updated
  def run!
    total_updated = 0

    # Scope to only records where TotalMonthlyIncome is missing.
    # This service does not fix records where the total is present but disagrees
    # with the individual income source amounts.
    missing_scope = @scope.where(IncomeFromAnySource: 1, TotalMonthlyIncome: nil)

    missing_scope.in_batches(of: BATCH_SIZE) do |batch|
      changed = []
      batch.each do |record|
        messages = Hmis::Hud::DataIntegrity::TotalIncomeReconciler.call(record)
        messages.each { |message| Rails.logger.info(message) }

        # Only persist records whose total was actually changed
        next unless record.changed.include?('TotalMonthlyIncome')

        # If this is a CSV importer staging record, recompute source_hash to keep it in sync.
        # The CSV importer uses this hash to detect changes between imports.
        record.set_source_hash if record.respond_to?(:set_source_hash)
        changed << record
      end
      next if changed.empty?

      persist!(changed)
      total_updated += changed.size
    end

    Rails.logger.info "Filled TotalMonthlyIncome on #{total_updated} IncomeBenefit records"
    total_updated
  end

  private

  def persist!(records)
    result = @model_class.import( # import skips PaperTrail and timestamps
      records,
      validate: false,
      timestamps: false,
      on_duplicate_key_update: {
        conflict_target: @conflict_target,
        columns: update_columns,
      },
    )
    raise "error: #{result.failed_instances.inspect}" if result.failed_instances.any?
  end

  def update_columns
    columns = [:TotalMonthlyIncome]

    # Only refresh source_hash on records that support it (versioned CSV importer staging records)
    columns << :source_hash if @model_class.column_names.include?('source_hash')

    columns
  end
end
