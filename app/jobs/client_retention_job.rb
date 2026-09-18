###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Nightly pass that marks the source clients of warehouse identities whose newest activity is
# older than their retention window, and clears marks for identities with fresh activity. Marks live in
# GrdaWarehouse::InactiveClient; every mark and unmark is logged with identifiers only.
# See docs/features/warehouse/client-data-retention.md.
class ClientRetentionJob < BaseJob
  queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

  BATCH_SIZE = 5_000

  def perform
    global_years = GrdaWarehouse::Config.get(:client_retention_years)
    return if global_years.nil?

    # timeout 0: a run still in progress means this one simply does nothing
    GrdaWarehouseBase.with_advisory_lock(self.class.name, timeout_seconds: 0) do
      instrument_as_maintenance_task(name: 'Mark inactive clients') do
        run!(global_years)
      end
    end
  end

  private def run!(global_years)
    @global_years = global_years
    @today = Date.current
    @counts = Hash.new(0)
    @run = GrdaWarehouse::ClientRetentionRun.create!(
      started_at: Time.current,
      global_retention_years: global_years,
      data_source_overrides: GrdaWarehouse::DataSource.where.not(client_retention_years: nil).pluck(:id, :client_retention_years).to_h,
    )

    # Full scan of every destination each night; if it outgrows the maintenance
    # window, restrict to rollups with an Exit.DateUpdated since the previous run plus those
    # already marked.
    GrdaWarehouse::Hud::Client.destination.in_batches(of: BATCH_SIZE) do |batch|
      process_batch(batch.pluck(:id))
    end

    @run.update!(
      completed_at: Time.current,
      evaluated_count: @counts[:evaluated],
      marked_count: @counts[:marked],
      unmarked_count: @counts[:unmarked],
    )
  end

  private def process_batch(destination_ids)
    rows = GrdaWarehouse::InactiveClient.rollup_activity(destination_ids: destination_ids, global_years: @global_years)
    @counts[:evaluated] += rows.size

    inactive = rows.select { |row| row[:last_activity_on] < @today - row[:retention_years].years }
    inactive_ids = inactive.map { |row| row[:destination_id] }

    # Marks are all-or-none per identity, so one marked source means the identity was marked.
    evaluated_source_ids = rows.flat_map { |row| source_ids_for(row) }
    marked_source_ids = GrdaWarehouse::InactiveClient.where(client_id: evaluated_source_ids).pluck(:client_id).to_set
    already_marked = rows.select { |row| source_ids_for(row).any? { |id| marked_source_ids.include?(id) } }.map { |row| row[:destination_id] }
    newly_marked = inactive_ids - already_marked
    cleared = already_marked - inactive_ids

    mark_rows = inactive.flat_map { |row| mark_rows_for(row) }
    # Insert for every inactive rollup, not only new ones, so a source merged into an
    # already-marked identity gets its own row; the unique index makes repeats no-ops.
    GrdaWarehouse::InactiveClient.insert_all(mark_rows, unique_by: :client_id) if mark_rows.any?
    # Every live source of an evaluated identity that is not inactive loses its mark: sources of
    # cleared identities, and sources that moved from a marked identity into an active one.
    stale = evaluated_source_ids - mark_rows.map { |r| r[:client_id] }
    GrdaWarehouse::InactiveClient.where(client_id: stale).delete_all if stale.any?

    rows_by_destination = rows.index_by { |row| row[:destination_id] }
    log('marked', newly_marked, rows_by_destination)
    log('unmarked', cleared, rows_by_destination)
    @counts[:marked] += newly_marked.size
    @counts[:unmarked] += cleared.size
  end

  private def source_ids_for(row)
    row[:source_clients].map { |sc| sc['client_id'] }
  end

  private def mark_rows_for(row)
    source_ids_for(row).uniq.map do |client_id|
      {
        client_id: client_id,
        marked_on: @today,
        last_activity_on: row[:last_activity_on],
        retention_years: row[:retention_years],
      }
    end
  end

  private def log(action, destination_ids, rows_by_destination)
    return if destination_ids.empty?

    entries = destination_ids.map do |destination_id|
      row = rows_by_destination[destination_id] || {}
      {
        run_id: @run.id,
        action: action,
        destination_client_id: destination_id,
        source_clients: row[:source_clients] || [],
        last_activity_on: row[:last_activity_on],
        retention_years: row[:retention_years],
        created_at: Time.current,
      }
    end
    GrdaWarehouse::ClientRetentionLogEntry.insert_all(entries)
  end
end
