###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Reconciles total monthly income discrepancies that may occur despite front-end validations,
# and on imported data.
# Calculates expected total from individual income sources and auto-corrects mismatches.
#
# todo @martha - logging and transactional safety
#
# Two entrypoints:
#   - #call(record): reconcile a single IncomeBenefit(-like) record in memory.
#     Returns `messages` indicating the changes made.
#   - .fill_missing_totals!: batch entrypoint that fills in missing TotalMonthlyIncome
#     across a scope of records, persists the changes, and logs messages.
#
class Hmis::Hud::DataIntegrity::TotalIncomeReconciler < Hmis::Hud::DataIntegrity::BaseReconciler
  # [[:Alimony, :AlimonyAmount], ...]
  INCOME_SOURCES = GrdaWarehouse::Hud::IncomeBenefit::SOURCES.to_a.freeze
  BATCH_SIZE = 1_000

  # Batch entrypoint. Fills in TotalMonthlyIncome on IncomeBenefit records that indicate
  # income (IncomeFromAnySource = 1) but are missing a total, by summing the individual income source amounts.
  #
  # This can be run from the console as a one-time cleanup, and also powers the opt-in CSV importer cleanup
  # (HmisCsvImporter::HmisCsvCleanup::FixMissingTotalMonthlyIncome). It owns missing-only selection, batching,
  # reconciliation, changed-only filtering, source_hash refresh (when the record supports it) and bulk persistence.
  #
  # Console usage (operates on HMIS IncomeBenefits in a data source):
  #   Hmis::Hud::DataIntegrity::TotalIncomeReconciler.fill_missing_totals!(data_source_id: ds_id)
  #
  # Callers that already have an explicit scope (e.g. versioned importer staging) should build the reconciler
  # and call the instance method directly, e.g.:
  #   new.fill_missing_totals!(scope: staging_scope, conflict_target: [:id, :importer_log_id])
  #
  # @param data_source_id [Integer] restrict to HMIS IncomeBenefits in this data source.
  # @return [Integer] number of records that were updated
  def self.fill_missing_totals!(data_source_id:)
    new.fill_missing_totals!(scope: Hmis::Hud::IncomeBenefit.hmis.where(data_source_id: data_source_id))
  end

  # @param record [Hmis::Hud::IncomeBenefit, GrdaWarehouse::Hud::Base] an IncomeBenefit record. May be a
  #   versioned CSV importer staging record, so we access HUD fields by their CamelCase names rather than
  #   the snake_case aliases (which are not defined on staging classes).
  def call(record)
    # note, we only perform reconciliation if the record indicates IncomeFromAnySource. Otherwise we leave any
    # issues to be flagged by DQ
    @messages = []
    if record.IncomeFromAnySource&.to_i == 1
      reconcile_total_income(record)
    else
      check_no_income_fields(record)
    end

    format_messages(record, @messages)
  end

  # @return [Integer] number of records that were updated
  def fill_missing_totals!(scope:, conflict_target: [:id])
    @model_class = scope.klass
    @conflict_target = conflict_target
    total_updated = 0

    missing_scope(scope).in_batches(of: BATCH_SIZE) do |batch|
      changed = []
      batch.each do |record|
        # todo @martha - refer to messages instead of checking changed?
        call(record)

        # Only persist records whose total was actually filled in
        next unless record.changed.include?('TotalMonthlyIncome')

        record.set_source_hash if record.respond_to?(:set_source_hash)
        changed << record
      end
      next if changed.empty?

      # todo @martha - transactional safety and logging?
      persist!(changed)
      total_updated += changed.size
    end

    Rails.logger.info "Filled TotalMonthlyIncome on #{total_updated} IncomeBenefit records"
    total_updated
  end

  protected

  def check_no_income_fields(record)
    total = record.TotalMonthlyIncome
    report(record, "Expected total_monthly_income to be zero or nil, was #{total}") if total.to_f.positive?
  end

  def reconcile_total_income(record)
    calculated_income = calculate_total_income(record)
    # Normalize nil TotalMonthlyIncome to 0 for comparison
    total_income = record.TotalMonthlyIncome.to_f
    # do nothing if total income matches calculated within tolerance
    return if (calculated_income - total_income).abs < 0.01

    # report and correct value
    report(record, "Total monthly income does not match calculated income. Expected #{record.TotalMonthlyIncome&.to_f.inspect} to equal calculated: #{calculated_income.inspect} (auto-corrected)")
    record.TotalMonthlyIncome = calculated_income
  end

  def calculate_total_income(record)
    result = 0
    INCOME_SOURCES.each do |source_field, amount_field|
      source = record.public_send(source_field)&.to_i
      amount = record.public_send(amount_field)&.to_f

      # we ignore the source field when calculating total value
      result += amount if amount&.positive?

      # report inconsistencies if the source was set to true
      if source == 1
        report(record, "Expected #{amount_field} to be provided but was #{amount.inspect}") if amount.nil? || amount&.negative? || amount&.zero?
      end
    end
    result
  end

  def report(record, message)
    tag = "#{record.class.name}##{record.id}"
    @messages << "#{tag}: #{message}"
  end

  private

  # IncomeBenefits that indicate income but are missing a total
  def missing_scope(scope)
    scope.where(IncomeFromAnySource: 1, TotalMonthlyIncome: nil)
  end

  # Only refresh source_hash on records that support it (versioned CSV importer staging records)
  def update_columns
    columns = [:TotalMonthlyIncome]
    columns << :source_hash if @model_class.column_names.include?('source_hash')
    columns
  end

  def persist!(records)
    # todo @martha - understand this better; it is from the cleanup util, should it be moved to a common place/concern?
    without_papertrail_or_timestamps do
      result = @model_class.import(
        records,
        validate: false,
        timestamps: false,
        on_duplicate_key_update: { # todo @martha -why are we worried about duplicate key updates? automated importer?
          conflict_target: @conflict_target,
          columns: update_columns,
        },
      )
      raise "error: #{result.failed_instances.inspect}" if result.failed_instances.any?
    end
  end

  def without_papertrail_or_timestamps
    ActiveRecord::Base.record_timestamps = false
    begin
      PaperTrail.request(enabled: false) do
        yield
      end
    ensure
      ActiveRecord::Base.record_timestamps = true
    end
  end
end
