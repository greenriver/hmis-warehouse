# frozen_string_literal: true

###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# One time migration of legacy scan card IDs into scan card codes. See OneTimeScanCardMigration20261020.
#
# Usage:
#   rails driver:hmis:one_time_scan_card_migration_20261020[cded_key]          # dry run (default)
#   rails driver:hmis:one_time_scan_card_migration_20261020[cded_key,true]     # dry run
#   rails driver:hmis:one_time_scan_card_migration_20261020[cded_key,false]    # apply
desc 'One time migration creating scan card codes from a Client custom data element (dry_run defaults to true)'
task :one_time_scan_card_migration_20261020, [:cded_key, :dry_run] => [:environment] do |_task, args|
  raise 'cded_key is required' if args[:cded_key].blank?

  dry_run = args[:dry_run].nil? || args[:dry_run].to_s == 'true'
  raise 'dry_run must be true or false' unless args[:dry_run].nil? || args[:dry_run].to_s.in?(['true', 'false'])

  OneTimeScanCardMigration20261020.new(cded_key: args[:cded_key], dry_run: dry_run).run!
end

# Creates one scan card code per value of a Client-owned custom data element, for
# migrating scan card IDs issued by a legacy system. Values are digits only and are
# left-padded with zeros to PAD_LENGTH; longer values are kept as-is.
#
# Skips and reports:
# - blank or non-numeric values
# - values that already belong to a scan card code (including soft-deleted) on another client,
#   or that appear on more than one client in the source data
# Values that already belong to a scan card code on the same client are left alone, so
# re-running is a no-op; a code soft-deleted by staff is not restored. Source custom data
# elements are not modified.
#
# Rows are inserted with insert_all, so no PaperTrail versions are written.
#
# Expects a single HMIS data source.
#
# Usage from a console (after `Rails.application.load_tasks`):
#   OneTimeScanCardMigration20261020.new(cded_key: 'some_cded_key', dry_run: true).run!
class OneTimeScanCardMigration20261020
  PAD_LENGTH = 7
  INSERT_BATCH_SIZE = 5_000
  # Max skipped rows printed per reason; full lists are on the returned Summary.
  REPORT_LIMIT = 50

  Row = Data.define(:custom_data_element_id, :client_id, :value)
  Summary = Data.define(:candidates, :created, :already_present, :invalid, :collisions, :dry_run)

  def initialize(cded_key:, dry_run: true, batch_size: INSERT_BATCH_SIZE)
    @cded_key = cded_key
    @dry_run = dry_run
    @batch_size = batch_size
  end

  def run!
    data_source = GrdaWarehouse::DataSource.hmis.sole
    cded = Hmis::Hud::CustomDataElementDefinition.find_by!(
      key: @cded_key,
      owner_type: Hmis::Hud::Client.sti_name,
      data_source: data_source,
    )

    rows = cde_rows(cded, data_source)
    invalid, valid = rows.partition { |row| row.value.blank? || !row.value.match?(/\A\d+\z/) }
    valid = valid.map { |row| row.with(value: row.value.rjust(PAD_LENGTH, '0')) }

    existing_owner = Hmis::ScanCardCode.with_deleted.where(value: valid.map(&:value).uniq).pluck(:value, :client_id).to_h
    source_owners = valid.group_by(&:value).transform_values { |group| group.map(&:client_id).uniq }

    collisions, ok = valid.partition do |row|
      source_owners[row.value].size > 1 || existing_owner.fetch(row.value, row.client_id) != row.client_id
    end
    already_present, to_create = ok.partition { |row| existing_owner.key?(row.value) }
    # A client can repeat the same value across CDE rows; create it once.
    to_create = to_create.uniq(&:value)

    created = insert!(to_create)

    summary = Summary.new(
      candidates: rows.size,
      created: created,
      already_present: already_present.size,
      invalid: invalid,
      collisions: collisions,
      dry_run: @dry_run,
    )
    report(cded, summary)
    summary
  end

  private

  def cde_rows(cded, data_source)
    Hmis::Hud::CustomDataElement.
      where(data_element_definition: cded, owner_type: Hmis::Hud::Client.sti_name).
      where(owner_id: Hmis::Hud::Client.where(data_source: data_source).select(:id)).
      order(:id).
      pluck(:id, :owner_id, :value_string).
      map { |id, client_id, value| Row.new(custom_data_element_id: id, client_id: client_id, value: value&.strip) }
  end

  def insert!(rows)
    return rows.size if @dry_run

    now = Time.current
    # All-or-nothing, so a failure partway through leaves no partial migration.
    Hmis::ScanCardCode.transaction do
      rows.each_slice(@batch_size) do |slice|
        Hmis::ScanCardCode.insert_all!(
          slice.map { |row| { client_id: row.client_id, value: row.value, created_at: now, updated_at: now } },
          returning: false,
        )
      end
    end
    rows.size
  end

  def prefix
    @dry_run ? '[DRY RUN] ' : ''
  end

  def report(cded, summary)
    verb = @dry_run ? 'would create' : 'created'
    puts "#{prefix}#{cded.key} (CDED #{cded.id}): #{summary.candidates} values, #{verb} #{summary.created} scan card codes, " \
         "#{summary.already_present} already present, #{summary.invalid.size} invalid, #{summary.collisions.size} collisions"
    report_skipped('Invalid', summary.invalid)
    report_skipped('Collision', summary.collisions)
  end

  def report_skipped(label, rows)
    rows.first(REPORT_LIMIT).each do |row|
      puts "#{prefix}#{label}: CDE #{row.custom_data_element_id}, client #{row.client_id}, value #{row.value.inspect}"
    end
    puts "#{prefix}... and #{rows.size - REPORT_LIMIT} more #{label.downcase} rows" if rows.size > REPORT_LIMIT
  end
end
