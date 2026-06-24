###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Reconciles staged HUD CSV data (from the Loader) with the warehouse.
#
# The import is authoritative for the projects in Project.csv and the date
# range in Export.csv. All warehouse rows within that scope are assumed
# deleted unless the incoming data proves otherwise ("guilty until proven
# innocent" via pending_date_deleted).
#
# Lifecycle:
#   pre_process! → validate → aggregate → cleanup → ingest! → post_process
#
# Ingestion (ingest!) runs four passes per HUD file:
#   0. mark_tree_as_dead   — flag all in-scope warehouse rows as pending deletion
#   1. add_new_data        — upsert staging rows whose hud_key is absent from the
#                            in-scope warehouse set (upsert handles keys that exist
#                            outside the scope, e.g. from a prior date range)
#   2. process_existing    — for rows present in both staging and warehouse:
#      a. mark_unchanged       — source_hash match → clear pending deletion
#      b. mark_incoming_older  — staging DateUpdated < warehouse → clear pending deletion
#      c. apply_updates        — everything still pending → overwrite warehouse from staging
#   3. remove_pending_deletes — soft-delete anything still flagged
#
# Terminology:
#   "involved scope" / "in-scope" — the set of warehouse rows this import is
#       authoritative over, defined by involved_warehouse_scope(data_source_id,
#       project_ids, date_range). Each per-file model implements this scope.
#   "aggregation" — optional enrollment combining for Night-by-Night ES projects
#       (see CombineEnrollments). Accommodates vendors that submit NbN ES stays
#       as a new Entry-Exit enrollment per night; aggregation merges those into a
#       single continuous enrollment. When active, staging data may include
#       enrollments outside the import date range so contiguous stays can be
#       merged correctly.
#
# @see docs/features/hmis-csv-importer.md for full data-flow documentation.
#
# Manual run:
#   loader = HmisCsvImporter::Loader::LoaderLog.last
#   imp = HmisCsvImporter::Importer::Importer.new(loader_id: loader.id, data_source_id: loader.data_source_id)
#   imp.import!

require 'memery'
require 'zlib'
require 'base64'

module HmisCsvImporter::Importer
  # @see docs/features/hmis-csv-importer.md for architecture and design details.
  class Importer
    include TsqlImport
    include NotifierConfig
    include HmisCsvImporter::HmisCsv
    include ArelHelper
    include Memery

    attr_accessor :import, :range, :data_source, :importer_log

    SELECT_BATCH_SIZE = 10_000
    INSERT_BATCH_SIZE = 5_000

    def initialize(
      loader_id:,
      data_source_id:,
      debug: true,
      deidentified: false,
      project_cleanup: true,
      dry_run: false
    )
      setup_notifier('HMIS CSV Importer')
      @loader_log = HmisCsvImporter::Loader::LoaderLog.find(loader_id.to_i)
      @data_source = GrdaWarehouse::DataSource.find(data_source_id.to_i)
      @debug = debug # no longer used for anything. instead we use logger.levels.
      @updated_source_client_ids = Set.new

      @deidentified = deidentified
      @project_cleanup = project_cleanup
      @current_version = @loader_log.version
      @dry_run = dry_run
      self.importer_log = setup_import
      importer_log.version = @current_version

      importable_files.each_key do |file_name|
        setup_summary(file_name)
      end
      log('De-identifying clients') if @deidentified
      log('Limiting to pre-approved projects') if @project_whitelist
    end

    private def log_ids
      {
        data_source_id: @data_source.id,
        loader_log_id: @loader_log&.id,
        importer_log_id: @importer_log.id,
      }
    end

    # Needs to return an import_log instance
    def import!(import_log = nil)
      start_import
      @import_log = import_log
      log_timing :analyze_tables
      log_timing :pre_process!
      log_timing :validate_data_set!
      log_timing :aggregate!
      log_timing :cleanup_data_set!
      log_timing :analyze_tables

      # Determine what changes will be made and make note for alerting and monitoring. This is only needed if the data source is configured to pause on errors.
      log_timing :precalculate_change_counts if @data_source.ever_pause_imports_with_errors? || @data_source.ever_notify_for_imports?

      # Send any notifications that might be relevant to the error state of this import
      notify_of_import_status

      # refuse to proceed with the import if there are any errors and that setting is in effect
      return pause_import if should_pause?
      # if this is a dry run, pause, but don't notify unless there are errors
      return pause_import if @dry_run

      ingest!
      log_timing :invalidate_aggregated_enrollments!
      complete_import
      post_process
    end

    def resume!
      return unless importer_log.resuming?

      Rails.logger.info "resume! #{hash_as_log_str log_ids}"

      # this isn't quite right, but we don't store it,
      # and we may have paused for a significant amount of time
      @started_at = Time.current
      ingest!
      log_timing :invalidate_aggregated_enrollments!
      complete_import
      post_process
    end

    ##
    # Determines whether the import process should be paused based on error thresholds.
    #
    # This method evaluates the configured settings for pausing imports due to errors and
    # checks the current status of the loader log. It aggregates error counts from different
    # sources and determines if they exceed the allowable threshold.
    #
    # The decision to pause is made based on the following conditions:
    # - If the data source is configured to pause imports due to errors or record changes.
    # - If the loader log status is not `'loaded'`, indicating the import has not progressed to that stage.
    # - If any individual file has exceeded its error threshold, the import is paused.
    #
    # @return [Boolean] `true` if the import should be paused due to exceeding error thresholds, otherwise `false`.
    #
    memoize def should_pause?
      return true unless @loader_log.status == 'loaded'

      return true if @data_source.ever_pause_imports_with_errors? && any_error_thresholds_met?

      @data_source.ever_pause_imports_with_record_changes? && any_record_count_thresholds_met?
    end

    ##
    # Determines if any file in the import process has exceeded its allowed error threshold.
    #
    # This method iterates over all import files and checks whether the number of errors
    # in each file surpasses the defined threshold. If any file's error count exceeds the
    # threshold set in the data source, the method returns `true`.
    #
    # @return [Boolean] `true` if any file has met or exceeded its error threshold, otherwise `false`.
    #
    memoize private def any_error_thresholds_met?
      return false unless @data_source.ever_notify_for_imports?

      # counts of expected rows in each file
      totals_by_filename = @loader_log.summary.map { |filename, data| [filename, data['total_lines'].to_i] }.to_h
      totals_by_filename.any? do |filename, total_count|
        @data_source.error_count_threshold_reached?(total_count, error_counts[filename])
      end
    end

    ##
    # Determines if any file in the import process has exceeded its allowed record count change threshold.
    #
    # This method evaluates the total number of records and absolute number of changes (additions minus removals)
    # for each file. If the number of changes exceeds the configured threshold for any file, the method
    # returns `true`.
    #
    # @return [Boolean] `true` if any file has met or exceeded its record count change threshold, otherwise `false`.
    #
    memoize private def any_record_count_thresholds_met?
      return false unless @data_source.ever_notify_for_imports?

      change_counts.values.any? do |data|
        total = data[:total_count]
        changes = data[:change_count]
        @data_source.record_count_threshold_reached?(total, changes)
      end
    end

    ##
    # Collects and aggregates import errors from the loader and import processes.
    #
    # This method retrieves error counts from different parts of the import process:
    # - Errors logged in the loader summary.
    # - Errors recorded in the {HmisCsvImporter::Importer::ImportError} model.
    # - Validation errors recorded in the {HmisCsvImporter::HmisCsvValidation::Base} model.
    #
    # It maps error counts to their respective filenames and ensures that the counts
    # are aggregated correctly without raising additional errors if files are missing.
    #
    # @return [Hash{String => Integer}] A hash where keys are filenames and values are the total error counts for each file.
    #
    memoize private def error_counts
      file_lookup = self.class.importable_files_map(@current_version).invert

      # Serialized hash of processing data persisted on the log model
      summary = @loader_log.summary
      # Initialize error counts grouped by filename
      counts = summary.map { |filename, data| [filename, data['total_errors'].to_i] }.to_h

      # Collect errors from ImportError model
      HmisCsvImporter::Importer::ImportError.where(
        importer_log_id: importer_log.id,
      ).
        group(:source_type).
        count.
        map do |k, count|
          # convert to filename keys
          filename = file_lookup[k.demodulize]

          counts[filename] += count
        end

      # Collect validation errors
      HmisCsvImporter::HmisCsvValidation::Base.where(
        type: HmisCsvImporter::HmisCsvValidation::Error.subclasses.map(&:name),
        importer_log_id: importer_log.id,
      ).
        group(:source_type).
        count.
        map do |k, count|
          # convert to filename keys
          filename = file_lookup[k.demodulize]
          # every file _should_ be present, but let's try not to throw any errors here
          next unless counts[filename]

          counts[filename] += count
        end
      counts
    end

    ##
    # Estimates the number of records that will be added and removed during the import process.
    #
    # This method calculates changes before ingestion to determine if the import
    # exceeds configured thresholds. It compares existing records in the warehouse
    # with incoming records from the import log to identify additions and removals.
    #
    # The results are stored in the `importer_log.summary` for each file, allowing these values
    # to be used in import threshold checks before committing data changes.
    #
    # @return [void]
    #
    private def precalculate_change_counts
      # Estimate change counts before processing to determine if the import should be paused.
      importable_files.each do |file, klass|
        importer_log.summary[file]['added']       = added_count(klass)
        importer_log.summary[file]['removed']     = klass.prevent_import_deletions? ? 0 : removed_count(klass)
        importer_log.summary[file]['total_count'] = existing_data_scope(klass).distinct.count(klass.hud_key)
      end
    end

    # Count of incoming hud_keys that do not yet exist in the warehouse.
    private def added_count(klass)
      anti_join_count(
        klass.incoming_data(importer_log_id: importer_log.id),
        existing_data_scope(klass),
        klass.hud_key,
      )
    end

    # Count of warehouse hud_keys not present in the incoming data.
    private def removed_count(klass)
      anti_join_count(
        existing_data_scope(klass),
        klass.incoming_data(importer_log_id: importer_log.id),
        klass.hud_key,
      )
    end

    # COUNT DISTINCT keys in `scope` that have no matching key in `other_scope`,
    # using NOT EXISTS to avoid NOT IN's 3-valued NULL semantics.
    private def anti_join_count(scope, other_scope, key)
      other_table = other_scope.select(key).arel.as('other')
      other_ref = Arel::Table.new('other')
      exists = Arel::SelectManager.new.
        from(other_table).
        where(other_ref[key].eq(scope.arel_table[key])).
        project(1)

      scope.where(exists.exists.not).distinct.count(key)
    end

    private def existing_data_scope(klass)
      klass.existing_data(
        data_source_id: data_source.id,
        project_ids: involved_project_ids,
        date_range: date_range,
      )
    end

    # Snapshots the hud_keys already present in the warehouse (within the
    # involved scope) into a temporary table, then yields a scope of staged
    # rows whose keys are NOT in that snapshot — i.e., the genuinely new rows.
    #
    # Without the temp table, every batch fetched by find_each would re-evaluate
    # the full involved_warehouse_scope query, which is expensive for large tables.
    private def with_new_records_scope(klass)
      conn = klass.connection
      key = klass.hud_key
      temp = tmp_table_name('existing_keys', klass.warehouse_class)

      existing_scope = existing_data_scope(klass)
      conn.execute("DROP TABLE IF EXISTS #{conn.quote_table_name(temp)}")
      conn.execute(<<~SQL)
        CREATE TEMP TABLE #{conn.quote_table_name(temp)} AS
          SELECT DISTINCT #{conn.quote_column_name(key)} AS hud_key
          FROM (#{existing_scope.select(key).where.not(key => nil).to_sql}) sub
      SQL
      conn.execute("CREATE INDEX ON #{conn.quote_table_name(temp)} (hud_key)")

      # NOT EXISTS instead of NOT IN because NOT IN returns no rows when any
      # value in the subquery is NULL (SQL three-valued logic).
      temp_table = Arel.sql(conn.quote_table_name(temp))
      exists = Arel::SelectManager.new.
        from(temp_table).
        where(Arel.sql('hud_key').eq(klass.arel_table[key])).
        project(1)
      new_data_scope = klass.incoming_data(importer_log_id: importer_log.id).
        where(exists.exists.not)
      yield new_data_scope
    ensure
      conn&.execute("DROP TABLE IF EXISTS #{conn.quote_table_name(temp)}")
    end

    ##
    # Collects and aggregates changes in record counts during the import process.
    #
    # This method calculates changes in records (additions and removals) for each importable file.
    # It determines the total number of changes by comparing additions and removals and associates
    # the changes with the corresponding file. Additionally, it retrieves the total record count
    # for of existing data that matches each file to provide more context about the scale of the changes.
    #
    # @return [Hash{String => Hash{Symbol => Integer}}] A hash where keys are filenames, and values
    #   are hashes containing:
    #   - `:change_count` (Integer): The absolute value of the difference between additions and removals.
    #   - `:total_count` (Integer): The total number of records for the corresponding file.
    #
    private def change_counts
      importer_log.summary.map do |file, data|
        to_add    = data['added']
        to_remove = data['removed']
        [
          file,
          {
            change_count: (to_add - to_remove).abs,
            total_count: data['total_count'].to_i,
          },
        ]
      end.to_h
    end

    ##
    # Sends notifications about the current import status.
    #
    # This method triggers a emails to users who are setup to receive status notifications for the data source
    # with the following details:
    # - Whether any error thresholds have been exceeded.
    # - Whether any record count change thresholds have been exceeded.
    # - Whether the import process should be paused.
    #
    # @return [void]
    #
    private def notify_of_import_status
      # don't do anything if we don't have an import log to reference.
      return unless @import_log

      @data_source.notify_of_import_status(
        import_log_id: @import_log.id,
        error_threshold_met: any_error_thresholds_met?,
        record_count_threshold_met: any_record_count_thresholds_met?,
        paused: should_pause?,
      )
    end

    private def analyze_tables
      importable_files.each_value do |klass|
        query = "ANALYZE #{klass.quoted_table_name}"
        klass.connection.execute(query)
      end
    end

    # Refresh statistics on all importable warehouse tables after mark_tree_as_dead
    # bulk-writes pending_date_deleted, so the planner has accurate selectivity for
    # the semi-join strategies used by mark_unchanged and mark_incoming_older.
    private def analyze_warehouse_tables
      importable_files.each_value do |klass|
        wh_klass = klass.warehouse_class
        wh_klass.connection.execute("ANALYZE #{wh_klass.quoted_table_name}")
      end
    end

    # Move all data from the data lake to either the structured, or aggregated tables
    def pre_process!
      importer_log.update(status: :pre_processing)

      importable_files.each do |file_name, klass|
        pre_process_class!(file_name, klass)
      end
    end

    private def required_file_names
      ['Export.csv', 'Project.csv']
    end

    private def use_ar_model_validations
      false
    end

    def pre_process_class!(file_name, klass)
      importer_log_id = importer_log.id
      scope = source_data_scope_for(file_name)
      # save some allocations be doing these only once
      pre_processed_at = Time.current
      bmk = Benchmark.measure do
        batch = []
        failures = []
        row_failures = []
        # Set any import overrides for this class and data source so we avoid going back to the db
        klass.import_overrides = import_overrides_for(file_name, @data_source.id)
        scope.find_each(batch_size: SELECT_BATCH_SIZE) do |source|
          row_failures = []

          # Avoiding newing up a AR model here is faster
          # run_row_validations and process_batch are both fine
          # to with with the raw source.hmis_data as a ActiveSupport::HashWithIndifferentAccess
          destination = klass.attrs_from(source, deidentified: @deidentified)
          destination['importer_log_id'] = importer_log_id
          destination['pre_processed_at'] = pre_processed_at

          destination['source_hash'] = klass.new(destination).calculate_source_hash

          row_failures = run_row_validations(klass, destination, file_name, importer_log)
          failures.concat row_failures.compact
          # Don't insert any where we have actual errors
          batch << destination unless validation_failures_contain_errors?(row_failures)
          if batch.count == INSERT_BATCH_SIZE
            process_batch!(klass, batch, file_name, type: 'pre_processed', upsert: klass.upsert?)
            batch = []
          end
          if failures.count == INSERT_BATCH_SIZE
            HmisCsvImporter::HmisCsvValidation::Base.import(failures, validate: use_ar_model_validations)
            failures = []
          end
        end
        process_batch!(klass, batch, file_name, type: 'pre_processed', upsert: klass.upsert?) if batch.present? # ensure we get the last batch
        HmisCsvImporter::HmisCsvValidation::Base.import(failures, validate: use_ar_model_validations) if failures.present?
      end
      records = scope.count
      stats = {
        pp_secs: bmk.real.round(3),
        pp_rps: ((records / bmk.real).round(3) unless records.zero?),
        pp_cpu: "#{(bmk.total * 100.0 / bmk.real).round}%",
      }
      importer_log.summary[file_name].merge!(stats)
      Rails.logger.debug do
        " Pre-processed #{klass.table_name} #{hash_as_log_str({ importer_log_id: importer_log_id, processed: records }.merge(stats))}"
      end
    end

    def self.expiring_models
      importable_files.values.filter do |model|
        # Don't expire or remove Export or Project records since they define the scope of a given import
        !model.name.demodulize.in?(['Export', 'Project'])
      end
    end

    private def import_overrides_for(file_name, data_source_id)
      HmisCsvImporter::ImportOverride.where(file_name: file_name, data_source_id: data_source_id).to_a.
        sort_by { |o| [o.specificity, o.id] } # least specific will run first
    end

    private def run_row_validations(klass, row, filename, importer_log)
      failures = []
      klass.hmis_validations.each do |column, checks|
        next unless checks.present?

        checks.each do |check|
          arguments = check.dig(:arguments) || {}
          failures << check[:class].check_validity!(row, column, **arguments)
        end
      end
      failures.compact!
      if failures.count.positive?
        importer_log.summary[filename]['total_flags'] ||= 0
        importer_log.summary[filename]['total_flags'] += failures.count
      end
      failures
    end

    private def validation_failures_contain_errors?(failures)
      failures.any?(&:skip_row?)
    end

    def invalidate_aggregated_enrollments!
      importable_files.each_value do |klass|
        aggregators = aggregators_from_class(klass, @data_source)
        next unless aggregators.present?

        log("Rebuilding aggregated enrollments with #{klass.name}")
        aggregators.each do |aggregator_klass|
          aggregator_klass.new(
            importer_log: @importer_log,
            date_range: date_range,
            version: @current_version,
          ).rebuild_warehouse_data
        end
      end
    end

    def aggregate!
      importer_log.update(status: :aggregating)
      importable_files.each_value do |klass|
        aggregators = aggregators_from_class(klass, @data_source)
        next unless aggregators.present?

        log("Aggregating #{klass.name}")
        aggregators.each do |aggregator_klass|
          aggregator = aggregator_klass.new(
            importer_log: @importer_log,
            date_range: date_range,
            version: @current_version,
          )
          aggregator.remove_deleted_overlapping_data!
          aggregator.copy_incoming_data!
          aggregator.aggregate!
        end
      end
    end

    def validate_data_set!
      importable_files.each do |filename, klass|
        failures = klass.run_complex_validations!(importer_log, filename)
        HmisCsvImporter::HmisCsvValidation::Base.import(failures) if failures.any?
      end
    end

    def cleanup_data_set!
      importer_log.update(status: :cleaning)
      importable_files.each_value do |klass|
        cleanups = cleanups_from_class(klass, @data_source)
        next unless cleanups.present?

        log("Cleaning #{klass.name}")
        cleanups.each do |cleanup_klass|
          cleanup = cleanup_klass.new(
            importer_log: @importer_log,
            date_range: date_range,
            version: @current_version,
          )
          cleanup.cleanup!
        end
      end
    end

    # Pass 0, Walk the tree starting from projects and mark all as dead (in date range where appropriate)
    # Pass 1, create any where hud-key isn't in warehouse in same data source and involved projects
    # Pass 2, pluck previous hash and DateUpdated from warehouse, joining on involved scope
    #   If hash is the same, mark as live
    #   If hash differs
    #     if the incoming DateUpdated is older, mark warehouse as live
    #     If the incoming DateUpdated is the same or newer, update warehouse from lake,
    #       mark client demographics dirty
    #       mark enrollment dirty
    #       if exit record changes also mark associated enrollment dirty
    #       mark warehouse live
    # Delete all marked as dead for data source
    # For any enrollments where history_generated_on is blank? || history_generated_on < Exit.ExitDate run equivalent of:
    # GrdaWarehouse::Tasks::ServiceHistory::Enrollment.batch_process_date_range!(range)
    # In here, add history_generated_on date to enrollment record
    def ingest!
      # Reset add/remove counts used for import thresholds
      reset_import_counts
      importer_log.update(status: :importing)
      # Mark everything that exists in the warehouse, that would be covered by this import
      # as pending deletion.  We'll remove the pending where appropriate
      log_timing :mark_tree_as_dead

      # mark_tree_as_dead just bulk-updated pending_date_deleted across all in-scope
      # rows; refresh planner statistics so subsequent queries see accurate estimates.
      log_timing :analyze_warehouse_tables

      # Add Export row
      log_timing :add_export_row

      # Add any records we don't have
      log_timing :add_new_data

      # Process existing records,
      # determine which records have changed and are newer
      log_timing :process_existing

      # Update all ExportIDs for corresponding existing warehouse records
      log_timing :update_export_ids

      # Sweep all remaining items in a pending delete state
      log_timing :remove_pending_deletes

      # Update the effective export end date of the export
      log_timing :set_effective_export_end_date

      # Run any after_ingest hooks
      log_timing :after_ingest
    end

    def after_ingest
      importable_files.each_value do |klass|
        next unless klass.respond_to?(:after_ingest!)

        klass.after_ingest!(
          data_source: data_source,
          project_ids: involved_project_ids,
        )
      end
    end

    def set_effective_export_end_date
      export_klass = importable_file_class('Export').reflect_on_association(:destination_record).klass
      export_klass.last.update(effective_export_end_date: (importable_files.except('Export.csv').map do |_, klass|
        klass.where(importer_log_id: @importer_log.id).maximum(:DateUpdated)
      end.compact + ['1900-01-01'.to_date]).max)
    end

    def aggregators_from_class(klass, data_source)
      basename = klass.name.split('::').last
      data_source.import_aggregators[basename]&.map(&:constantize)
    end

    def cleanups_from_class(klass, data_source)
      basename = klass.name.split('::').last
      data_source.import_cleanups[basename]&.map(&:constantize)
    end

    # Capture executed sql for debugging. Also disable nested loops
    # min_duration defaults to 1 minute
    def with_sql_log(phase, klass, name: nil, min_duration: 60_000)
      queries = []
      callback = lambda { |event|
        payload_sql = event.payload[:sql].squish
        next if payload_sql =~ /ROLLBACK|COMMIT|BEGIN|SAVEPOINT/
        next if event.duration < min_duration

        binds = (event.payload[:binds] || []).map { |bind| { name: bind.name || '?', value: bind.value_for_database.inspect } }
        query_data = { sql: payload_sql.squish, binds: binds }

        compressed_query = begin
          # decode with Zlib::Inflate.inflate(Base64.decode64(str))
          Base64.strict_encode64(Zlib::Deflate.deflate(query_data.to_json)).chomp
        rescue JSON::GeneratorError => e
          Rails.logger.error("JSON serialization failed: #{e.message}")
          nil
        rescue Zlib::Error => e
          Rails.logger.error("Compression failed: #{e.message}")
          nil
        end

        queries << {
          'compressed_query' => compressed_query,
          'duration' => event.duration / 1000, # convert to seconds
        }
      }

      result = nil
      GrdaWarehouseBase.disable_nestloop do
        ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') do
          result = yield
        end
      end

      scope_name = [klass.name.demodulize, name].compact.join('.')
      importer_log.log_phase(phase, **{ scope_name => queries }) if queries.any?
      result
    end

    def mark_tree_as_dead
      file_count = 0
      importable_files.each_value do |klass|
        file_count += 1
        Rails.logger.info "[#{file_count}/#{total_files}] Marking tree as dead for #{klass.name}..."
        with_sql_log(__method__, klass, name: 'involved_warehouse_scope') do
          klass.mark_tree_as_dead(
            data_source_id: data_source.id,
            project_ids: involved_project_ids,
            date_range: date_range,
            pending_date_deleted: Date.current,
            importer_log_id: @importer_log.id,
          )
        end
      end
    end

    def add_export_row
      destination_class = export_record.class.reflect_on_association(:destination_record).klass
      destination_export = destination_class.where(
        data_source_id: data_source.id,
        ExportID: export_record.ExportID,
      ).first_or_create
      destination_export.update(export_record.as_destination_record.attributes.except('id'))
    end

    def update_export_ids
      importable_files.each do |_, klass|
        # Export has already been processed
        next if klass.hud_key == :ExportID

        involved_project_ids.each_slice(250) do |project_ids_slice|
          klass.involved_warehouse_scope(
            data_source_id: data_source.id,
            project_ids: project_ids_slice,
            date_range: date_range,
          ).update_all(ExportID: export_record.ExportID)
        end
      end
    end

    # Upsert staged rows whose hud_key doesn't yet exist in the warehouse
    # (within the involved scope). This is step 1 of ingestion — it runs
    # before process_existing, so any key already present in the warehouse is
    # skipped here and handled later by mark_unchanged / mark_incoming_older /
    # apply_updates.
    #
    # "New" is determined via a NOT EXISTS anti-join against a temp table
    # snapshot of warehouse hud_keys (see with_new_records_scope). Uses upsert
    # rather than plain insert because a matching hud_key may exist outside the
    # involved scope (e.g., from a prior date range import).
    def add_new_data
      file_count = 0
      importable_files.each do |file_name, klass|
        file_count += 1
        Rails.logger.info "[#{file_count}/#{total_files}] Adding new data for #{file_name}..."
        # Augmentation classes will always be updating existing records
        next if custom_augmentation?(klass)

        preload_custom_file_data(klass)

        destination_class = klass.reflect_on_association(:destination_record).klass

        # When enrollment aggregation is active (Night-by-Night ES projects),
        # CombineEnrollments writes consolidated enrollments into the staging
        # table that can span beyond the import's date range. This means the
        # "added" count in the log may be larger than expected.
        upsert = !destination_class.name.in?(un_updateable_warehouse_classes)

        bmk = Benchmark.measure do
          upsert_new_records_in_batches(klass, destination_class, file_name, upsert: upsert)
        end
        log_phase_stats(file_name, bmk, type: 'added', destination_class: destination_class)
      end
    end

    # Iterates staged rows that have no matching hud_key in the warehouse and
    # flushes them to the warehouse destination table in INSERT_BATCH_SIZE chunks.
    #
    # Columns are derived from the first record's attributes
    private def upsert_new_records_in_batches(klass, destination_class, file_name, upsert:)
      batch = []
      columns = nil
      with_new_records_scope(klass) do |new_data_scope|
        with_sql_log(:add_new_data, klass, name: 'new_data') do
          new_data_scope.find_each(batch_size: SELECT_BATCH_SIZE) do |row|
            batch << row.as_destination_record
            next unless batch.count == INSERT_BATCH_SIZE

            columns ||= batch.first.attributes.keys - ['id']
            process_batch!(destination_class, batch, file_name, columns: columns, type: 'added', upsert: upsert)
            batch = []
          end
        end
      end
      return unless batch.present?

      columns ||= batch.first.attributes.keys - ['id']
      process_batch!(destination_class, batch, file_name, columns: columns, type: 'added', upsert: upsert)
    end

    # Records benchmark timings for a completed ingest phase into the importer
    # log summary and emits a debug log line.
    # +type+ is the summary key prefix (e.g., 'added', 'updated').
    private def log_phase_stats(file_name, bmk, type:, destination_class:)
      records = summary_for(file_name, type) || 0
      stat_prefix = type == 'added' ? 'add' : type
      stats = {
        "#{stat_prefix}_secs": bmk.real.round(3),
        "#{stat_prefix}_rps": (records.zero? ? nil : (records / bmk.real).round(3)),
        "#{stat_prefix}_cpu": "#{(bmk.total * 100.0 / bmk.real).round}%",
      }.compact
      importer_log.summary[file_name].merge!(stats)
      Rails.logger.debug do
        "  #{type.capitalize} #{destination_class.table_name} #{hash_as_log_str({ type.to_sym => records }.merge(stats).merge(log_ids))}"
      end
    end

    # Cache ID lookups for custom files
    def preload_custom_file_data(klass)
      return unless custom_file?(klass)

      klass.cache_mapped_attributes(importer_log_id: importer_log.id)
    end

    def un_updateable_warehouse_classes
      [
        'GrdaWarehouse::Hud::Export',
        'GrdaWarehouse::Hud::Client',
      ]
    end

    def process_existing
      # TODO: This could be parallelized
      total_files = importable_files.count
      file_count = 0
      importable_files.each do |file_name, klass|
        file_count += 1
        Rails.logger.info "[#{file_count}/#{total_files}] Processing existing records for #{file_name}..."
        preload_custom_file_data(klass)
        with_sql_log(__method__, klass) do
          Rails.logger.info "  Marking unchanged records for #{file_name}..."
          mark_unchanged(klass, file_name)
          Rails.logger.info "  Marking incoming older records for #{file_name}..."
          mark_incoming_older(klass, file_name)
          Rails.logger.info "  Applying updates for #{file_name}..."
          apply_updates(klass, file_name)
          Rails.logger.info "  Completed processing #{file_name}"
        end
      end
    end

    # Final step of ingestion: soft-delete warehouse rows still flagged with
    # pending_date_deleted. These are records that were in-scope but not
    # accounted for by add_new_data, mark_unchanged, mark_incoming_older, or
    # apply_updates — meaning the incoming CSV no longer contains them.
    #
    # Three special cases:
    #   prevent_import_deletions? — some file types opt out of deletions entirely;
    #   Client (PersonalID) — partial data sources may not include all clients;
    #   Everything else — batched soft-delete (set DateDeleted, clear flag).
    def remove_pending_deletes
      importable_files.each do |file_name, klass|
        # Never delete Exports
        next if klass.hud_key == :ExportID
        # Augmented data should never delete records since it should only update existing records
        next if custom_augmentation?(klass)

        # If the klass does not allow deletions through the import process, remove the pending deletion flag from all klass records associated with this import.
        if klass.prevent_import_deletions?
          existing_destination_data_scope(klass).update_all(pending_date_deleted: nil, source_hash: nil)
        elsif klass.hud_key == :PersonalID
          # Clients need to be treated differently for the situation where we are importing a partial data source
          existing = existing_destination_data_scope(klass)
          # for everyone who would have been included in this import, but didn't get
          # processed above, set their source hash to nil so future imports will fix them
          with_sql_log(__method__, klass, name: 'existing_destination_data_scope') do
            existing.joins(enrollments: :project).
              merge(GrdaWarehouse::Hud::Enrollment.open_during_range(date_range)).
              merge(GrdaWarehouse::Hud::Project.where(id: involved_project_ids)).
              update_all(source_hash: nil)
            existing.update_all(pending_date_deleted: nil)
          end
        else
          delete_count = klass.pending_deletions(data_source_id: data_source.id, project_ids: involved_project_ids, date_range: date_range).count
          batch_soft_delete(klass, existing_destination_data_scope(klass))
          note_processed(file_name, delete_count, 'removed')
        end
      end
    end

    def involved_project_ids
      @involved_project_ids ||= importable_files['Project.csv'].
        where(importer_log_id: importer_log.id).
        pluck(:ProjectID)
    end

    private def existing_destination_data_scope(klass)
      klass.existing_destination_data(
        data_source_id: data_source.id,
        project_ids: involved_project_ids,
        date_range: date_range,
      )
    end

    # At this point,
    #   * All new data has been added
    #   * All extraneous data has been deleted
    #   * All unchanged data has been marked as live
    #   * All existing data currently marked as delete pending, should be updated from the incoming data
    # apply updates will:
    #   Mark client demographics dirty
    #   Mark enrollment dirty, for Enrollment and Exit tables
    #   Mark warehouse live
    private def apply_updates(klass, file_name)
      # Exports are always inserts, never updates
      return if klass.hud_key == :ExportID

      # Custom augmentation files have their own optimized path
      return apply_augmentation_updates(klass, file_name) if custom_augmentation?(klass)

      destination_class = klass.reflect_on_association(:destination_record).klass
      # Rails.logger.debug "Updating #{destination_class.name} #{hash_as_log_str log_ids}"
      # existing = existing_destination_data_scope(klass).distinct.pluck(klass.hud_key)
      bmk = Benchmark.measure do
        batch = []
        upsert_columns = destination_class.upsert_column_names(version: importer_log.version)

        Rails.logger.info "Processing existing records for #{file_name} in batches"

        existing_destination_data_scope(klass).in_batches(of: SELECT_BATCH_SIZE) do |relation|
          hud_keys = relation.pluck(klass.hud_key)
          klass.should_import.where(
            importer_log_id: @importer_log.id,
            klass.hud_key => hud_keys,
          ).find_each(batch_size: SELECT_BATCH_SIZE) do |source|
            batch << prepare_destination_for_update(klass, source.as_destination_record)
            if batch.count == INSERT_BATCH_SIZE
              # Client model doesn't have a uniqueness constraint because of the warehouse data source
              # so these must be processed more slowly
              if klass.hud_key == :PersonalID
                Rails.logger.info "Processing #{batch.count} records individually for #{file_name}"
                batch.each do |incoming|
                  destination_class.where(
                    data_source_id: incoming.data_source_id,
                    PersonalID: incoming.PersonalID,
                  ).with_deleted.update_all(incoming.slice(klass.upsert_column_names(version: importer_log.version)))
                end
                note_processed(file_name, batch.count, 'updated')
              else
                Rails.logger.info "Processing #{batch.count} records in bulk for #{file_name}"
                process_batch!(destination_class, batch, file_name, type: 'updated', upsert: true, columns: upsert_columns)
              end
              batch = []
            end
          end
        end
        if batch.present? # ensure we get the last batch
          if klass.hud_key == :PersonalID
            Rails.logger.info "Processing final batch of #{batch.count} records individually for #{file_name}"
            batch.each do |incoming|
              destination_class.where(
                data_source_id: incoming.data_source_id,
                PersonalID: incoming.PersonalID,
              ).with_deleted.update_all(incoming.slice(klass.upsert_column_names(version: importer_log.version)))
            end
            note_processed(file_name, batch.count, 'updated')
          else
            Rails.logger.info "Processing final batch of #{batch.count} records in bulk for #{file_name}"
            process_batch!(destination_class, batch, file_name, type: 'updated', upsert: true, columns: upsert_columns)
          end
        end

        flush_dirty_enrollments_for_exit(klass)
        Rails.logger.info "Completed applying updates for #{file_name}"
      end
      records = summary_for(file_name, 'updated') || 0
      stats = {
        up_secs: bmk.real.round(3),
        up_rps: ((records / bmk.real).round(3) unless records.zero?),
        up_cpu: "#{(bmk.total * 100.0 / bmk.real).round}%",
      }
      importer_log.summary[file_name].merge!(stats)
      Rails.logger.debug do
        "  Updated #{destination_class.table_name} #{hash_as_log_str({ updated: records }.merge(stats).merge(log_ids))}"
      end
    end

    # Process updates for custom augmentation files
    # These files only update existing records and never add new ones
    private def apply_augmentation_updates(klass, file_name)
      destination_class = klass.reflect_on_association(:destination_record).klass
      bmk = Benchmark.measure do
        batch = []
        upsert_columns = augmentation_upsert_columns(klass)

        # Drive from the source data (the augmentation file) rather than the warehouse
        # This prevents scanning the entire warehouse table when only a few records are being updated
        # and is generally more memory efficient for sparse updates
        klass.should_import.where(importer_log_id: @importer_log.id).find_in_batches(batch_size: SELECT_BATCH_SIZE) do |source_batch|
          hud_keys = source_batch.map { |r| r[klass.hud_key] }

          # Identify which of these source records match valid existing destination records
          # We must respect the existing_destination_data_scope (date range, project constraints)
          valid_keys = existing_destination_data_scope(klass).
            where(klass.hud_key => hud_keys).
            pluck(klass.hud_key).
            to_set

          source_batch.each do |source|
            next unless valid_keys.include?(source[klass.hud_key])

            batch << prepare_destination_for_update(klass, source.as_destination_record)

            next unless batch.count == INSERT_BATCH_SIZE

            Rails.logger.info "Processing #{batch.count} augmentation records in bulk for #{file_name}"
            process_batch!(destination_class, batch, file_name, type: 'updated', upsert: true, columns: upsert_columns, update_only: true)
            batch = []
          end
        end

        if batch.present?
          Rails.logger.info "Processing final batch of #{batch.count} augmentation records in bulk for #{file_name}"
          process_batch!(destination_class, batch, file_name, type: 'updated', upsert: true, columns: upsert_columns, update_only: true)
        end

        flush_dirty_enrollments_for_exit(klass)

        Rails.logger.info "Completed applying augmentation updates for #{file_name}"
      end

      records = summary_for(file_name, 'updated') || 0
      stats = {
        up_secs: bmk.real.round(3),
        up_rps: ((records / bmk.real).round(3) unless records.zero?),
        up_cpu: "#{(bmk.total * 100.0 / bmk.real).round}%",
      }
      importer_log.summary[file_name].merge!(stats)
      Rails.logger.debug do
        "  Updated #{destination_class.table_name} #{hash_as_log_str({ updated: records }.merge(stats).merge(log_ids))}"
      end
    end

    ##
    # Prepares a destination record for updating during the import process.
    #
    # This method modifies the destination record by:
    # - Removing the pending deletion flag
    # - Ensuring the correct data source ID is set
    # - Marking the record dirty based on its type (Client, Enrollment, or Exit)
    #
    # Side effects:
    # - For Client records: sets demographic_dirty flag and tracks client ID for post-processing
    # - For Enrollment records: clears processed_as to trigger service history regeneration
    # - For Exit records: tracks enrollment ID for batch update of associated enrollments
    #
    # @param klass [Class] The source class being processed
    # @param destination [ActiveRecord::Base] The destination record to prepare
    # @return [ActiveRecord::Base] The prepared destination record
    #
    private def prepare_destination_for_update(klass, destination)
      destination.pending_date_deleted = nil
      destination.data_source_id = data_source.id
      mark_record_dirty(klass, destination)
      destination
    end

    private def mark_record_dirty(klass, destination)
      case klass.hud_key
      when :PersonalID
        destination.demographic_dirty = true
        track_updated_client(destination.PersonalID)
      when :EnrollmentID
        destination.processed_as = nil
      when :ExitID
        # These are tracked separately so we can bulk update them at the end
        track_dirty_enrollment(destination.EnrollmentID)
      end
    end

    private def track_updated_client(personal_id)
      @updated_source_client_ids << personal_id if personal_id.present?
    end

    private def augmentation_upsert_columns(klass)
      columns = klass.upsert_column_names(version: importer_log.version)
      columns << :pending_date_deleted
      case klass.hud_key
      when :PersonalID
        columns << :demographic_dirty
      when :EnrollmentID
        columns << :processed_as
        # Exit records don't have processed_as; their dirty tracking
        # is handled via enrollment bulk update after processing
      end
      columns.uniq
    end

    # First pass of process_existing: clear pending_date_deleted on warehouse
    # rows whose source_hash already matches the incoming staged row. These
    # records haven't changed, so they don't need an update — just rescue them
    # from the soft-delete that mark_tree_as_dead queued up.
    #
    # Rows that don't match here (hash mismatch or NULL warehouse source_hash)
    # fall through to mark_incoming_older, then apply_updates.
    private def mark_unchanged(klass, file_name)
      return if klass.hud_key == :ExportID
      return if custom_augmentation?(klass)

      staging = klass.arel_table
      wh      = klass.warehouse_class.arel_table
      incoming_scope = klass.should_import.where(importer_log_id: @importer_log.id)

      # Staging source_hash is always non-NULL; warehouse source_hash can be NULL
      # to flag records for re-evaluation. SQL equality returns NULL (not true)
      # for NULL warehouse rows, so they correctly fall through to apply_updates.
      exists = incoming_scope.
        where(staging[klass.hud_key].eq(wh[klass.hud_key])).
        where(staging[:source_hash].eq(wh[:source_hash])).
        select(1).arel.exists
      matched_scope = existing_destination_data_scope(klass).
        where.not(DateUpdated: nil).
        where(exists)

      Rails.logger.info { "Processing Unchanged for #{file_name}: #{incoming_scope.count} incoming, #{matched_scope.count} unchanged" }
      batch_clear_pending_deletion(klass, matched_scope, file_name)
    end

    # Arel node: CAST(col AT TIME ZONE 'UTC' AT TIME ZONE '<local>' AS DATE)
    # The DB stores naive timestamps in UTC; this converts to the app's local
    # timezone before extracting the date so day boundaries match
    private def local_date_cast_arel(conn, arel_column)
      tz = Time.zone.tzinfo.name
      utc_tz = Arel::Nodes::SqlLiteral.new("'UTC'")
      local_tz = Arel::Nodes::SqlLiteral.new(conn.quote(tz))

      at_utc = Arel::Nodes::InfixOperation.new('AT TIME ZONE', arel_column, utc_tz)
      at_local = Arel::Nodes::InfixOperation.new('AT TIME ZONE', at_utc, local_tz)

      Arel::Nodes::NamedFunction.new('CAST', [Arel::Nodes::As.new(at_local, Arel.sql('DATE'))])
    end

    # Clear pending deletion for warehouse rows where the incoming DateUpdated
    # (by local-timezone date) is strictly older than the warehouse value.
    # The warehouse copy is newer, so we keep it and skip the incoming row.
    # Runs after mark_unchanged, so only hash-mismatched rows reach here.
    # Skipped when this is the most recent export for the data source, because
    # the latest export is authoritative regardless of DateUpdated.
    private def mark_incoming_older(klass, file_name)
      return if klass.hud_key == :ExportID
      return if custom_augmentation?(klass)
      return if most_recent_export_for_ds?

      staging = klass.arel_table
      wh      = klass.warehouse_class.arel_table
      incoming_scope = klass.should_import.where(importer_log_id: @importer_log.id).
        where.not(DateUpdated: nil)

      conn = klass.connection
      staging_date = local_date_cast_arel(conn, staging[:DateUpdated])
      wh_date      = local_date_cast_arel(conn, wh[:DateUpdated])

      exists = incoming_scope.
        where(staging[klass.hud_key].eq(wh[klass.hud_key])).
        where(Arel::Nodes::InfixOperation.new('<', staging_date, wh_date)).
        select(1).arel.exists
      matched_scope = existing_destination_data_scope(klass).
        where.not(DateUpdated: nil).
        where(exists)

      Rails.logger.info { "Processing Incoming Older for #{file_name}: #{incoming_scope.count} incoming, #{matched_scope.count} unchanged" }
      batch_clear_pending_deletion(klass, matched_scope, file_name)
    end

    # Creates a session-scoped temp table of IDs materialised from `scope`, builds
    # an index on it, yields the quoted temp-table name for the caller to drive its
    # own batched UPDATE, then drops the table in ensure.
    private def with_temp_id_table(conn, name, scope)
      conn.execute("DROP TABLE IF EXISTS #{conn.quote_table_name(name)}")
      conn.execute(<<~SQL)
        CREATE TEMP TABLE #{conn.quote_table_name(name)} AS
          SELECT id FROM (#{scope.select(:id).to_sql}) sub
      SQL
      conn.execute("CREATE INDEX ON #{conn.quote_table_name(name)} (id)")
      yield conn.quote_table_name(name)
    ensure
      conn&.execute("DROP TABLE IF EXISTS #{conn.quote_table_name(name)}")
    end

    # Temp tables are session-scoped, but we include a random suffix as a
    # defensive measure against name collisions. The full name is truncated
    # to PostgreSQL's 63-character identifier limit.
    private def tmp_table_name(prefix, klass)
      suffix = SecureRandom.hex(4) # 8 chars
      base = "tmp_#{prefix}_#{klass.table_name}_"
      "#{base.first(63 - suffix.length)}#{suffix}"
    end

    # Materialize matched IDs into a temp table so the expensive semi-join runs once,
    # then batch UPDATE from the temp table.
    private def batch_clear_pending_deletion(klass, matched_scope, file_name)
      conn = klass.warehouse_class.connection
      update_base = klass.warehouse_class
      update_base = update_base.with_deleted if klass.warehouse_class.paranoid?
      tmp_name = tmp_table_name('unchanged', klass.warehouse_class)

      with_temp_id_table(conn, tmp_name, matched_scope) do |quoted_temp|
        last_id = 0
        loop do
          result = conn.execute(<<~SQL)
            UPDATE #{update_base.quoted_table_name} wh SET pending_date_deleted = NULL
            FROM (
              SELECT id FROM #{quoted_temp}
              WHERE id > #{last_id}
              ORDER BY id LIMIT #{INSERT_BATCH_SIZE}
            ) batch
            WHERE wh.id = batch.id
            RETURNING wh.id
          SQL
          break if result.ntuples.zero?

          last_id = result.map { |r| r['id'].to_i }.max
          note_processed(file_name, result.ntuples, 'unchanged')
        end
      end
    end

    # Materialize delete-pending IDs into a temp table, then batch soft-delete.
    private def batch_soft_delete(klass, scope)
      conn = klass.warehouse_class.connection
      update_base = klass.warehouse_class
      update_base = update_base.with_deleted if klass.warehouse_class.paranoid?
      deleted_at = conn.quote(Time.current)
      tmp_name = tmp_table_name('pending_deletes', klass.warehouse_class)

      with_temp_id_table(conn, tmp_name, scope) do |quoted_temp|
        last_id = 0
        loop do
          result = conn.execute(<<~SQL)
            UPDATE #{update_base.quoted_table_name} wh
            SET pending_date_deleted = NULL,
                "DateDeleted" = #{deleted_at},
                source_hash = NULL
            FROM (
              SELECT id FROM #{quoted_temp}
              WHERE id > #{last_id}
              ORDER BY id LIMIT #{INSERT_BATCH_SIZE}
            ) batch
            WHERE wh.id = batch.id
            RETURNING wh.id
          SQL
          break if result.ntuples.zero?

          last_id = result.map { |r| r['id'].to_i }.max
        end
      end
    end

    private def track_dirty_enrollment(enrollment_id)
      @track_dirty_enrollment ||= Set.new
      @track_dirty_enrollment << enrollment_id
    end

    private def dirty_enrollment_ids
      @track_dirty_enrollment
    end

    private def clear_dirty_enrollment_ids
      @track_dirty_enrollment = nil
    end

    # Flush tracked dirty enrollments to the database and clear the tracking set
    # Used after processing Exit records to mark associated enrollments for reprocessing
    private def flush_dirty_enrollments_for_exit(klass)
      return unless klass.hud_key == :ExitID
      return unless dirty_enrollment_ids.present?

      GrdaWarehouse::Hud::Enrollment.where(data_source_id: data_source.id, EnrollmentID: dirty_enrollment_ids).
        update_all(processed_as: nil)
      # Clear the set to prevent duplicate processing if multiple Exit files are imported
      clear_dirty_enrollment_ids
    end

    private def import_options(klass, columns)
      options = {
        on_duplicate_key_update: {
          conflict_target: klass.conflict_target,
          columns: columns,
        },
      }
      options[:on_duplicate_key_update][:index_predicate] = klass.index_predicate if klass.respond_to?(:index_predicate)

      options
    end

    # Flush an array of AR model instances to the database via activerecord-import.
    # Three modes controlled by the caller:
    #   update_only: true  → bulk UPDATE via VALUES list (augmentation files that
    #                        only modify existing warehouse rows, never insert)
    #   upsert: true       → INSERT ... ON CONFLICT UPDATE (the normal path for
    #                        add_new_data and apply_updates)
    #   upsert: false      → plain INSERT (Export and Client, which lack a usable
    #                        uniqueness constraint for ON CONFLICT)
    #
    # On any ActiveRecord or PG error the entire batch is retried row-by-row so
    # a single bad record doesn't block the rest; per-row failures are logged to
    # import_errors.
    private def process_batch!(klass, batch, file_name, type:, upsert:, columns: klass.upsert_column_names(version: importer_log.version), update_only: false)
      Rails.logger.debug { "process_batch! #{klass} #{upsert ? 'upsert' : 'import'} #{batch.size} records" }
      klass.logger.silence(Logger::WARN) do
        if update_only
          bulk_update_batch!(klass, batch, columns)
        elsif upsert
          klass.import(
            batch,
            **import_options(klass, columns),
            validate: use_ar_model_validations,
          )
        else
          klass.import(batch, validate: use_ar_model_validations)
        end
        note_processed(file_name, batch.count, type)
      end
      return nil
    rescue ActiveRecord::ActiveRecordError, PG::Error => e
      log "batch failed: #{e.message}... processing records one at a time"
      errors = []
      batch.each do |row|
        if update_only
          where_clause = { data_source_id: row.data_source_id }.merge(
            Array.wrap(klass.conflict_target).to_h { |key| [key, row[key]] },
          )
          klass.where(where_clause).with_deleted.update_all(row.slice(columns))
        elsif upsert
          klass.import(
            Array.wrap(row),
            **import_options(klass, columns),
            validate: use_ar_model_validations,
            batch_size: 1,
          )
        else
          klass.import(Array.wrap(row), validate: use_ar_model_validations, batch_size: 1)
        end
        note_processed(file_name, 1, type)
      rescue ActiveRecord::ActiveRecordError, PG::Error => e
        errors << add_error(file: file_name, klass: klass, source_id: row[:source_id] || row[:source_hash], message: e.message)
      end
      @importer_log.import_errors.import(errors)
    end

    # Use postgres bulk update for performance
    # This will be used for data that is augmenting an existing warehouse class
    # that never needs to add new rows.
    # NOTE: data that augments the client table is handled differently
    # as that table does not currently have a uniqueness constraint compatible
    # with this method
    private def bulk_update_batch!(klass, batch, columns)
      conflict_keys = Array.wrap(klass.conflict_target)
      update_cols = columns - conflict_keys + [:data_source_id]
      value_rows = batch.map do |record|
        values = update_cols.map do |col|
          value = record.public_send(col.to_sym)
          if value.nil?
            # Cast NULL to the appropriate type based on the database column type
            cast_null_for_column_type(klass, col)
          else
            klass.connection.quote(value)
          end
        end
        "(#{values.join(', ')})"
      end
      sql_values = value_rows.join(",\n")
      all_cols_for_values = update_cols.map do |c|
        klass.connection.quote_column_name(c)
      end.join(', ')
      set_statements = update_cols.map do |c|
        qc = klass.connection.quote_column_name(c)
        "#{qc} = v.#{qc}"
      end.join(', ')
      table_name = klass.quoted_table_name
      where_conditions = conflict_keys.map do |c|
        # conflict keys are already quoted
        "#{table_name}.#{c} = v.#{c}"
      end.join(' AND ')
      sql = <<~SQL
        UPDATE #{table_name}
        SET #{set_statements}
        FROM (VALUES #{sql_values}) AS v(#{all_cols_for_values})
        WHERE #{where_conditions}
      SQL
      klass.connection.execute(sql)
    end

    private def cast_null_for_column_type(klass, column_name)
      column = klass.columns_hash[column_name.to_s]
      return 'NULL' unless column

      case column.type
      when :integer, :bigint, :smallint
        'NULL::integer'
      when :decimal, :float, :numeric
        'NULL::numeric'
      when :boolean
        'NULL::boolean'
      when :date
        'NULL::date'
      when :datetime, :timestamp
        'NULL::timestamp'
      when :text, :string
        'NULL::text'
      else
        'NULL'
      end
    end

    private def source_data_scope_for(file_name)
      scope = loader_class.loadable_files(importer_log.version)[file_name]
      scope.unscoped.where(loader_id: @loader_log.id)
    end

    private def loader_class
      HmisCsvImporter::Loader::Loader
    end

    private def date_range
      @date_range ||= Filters::DateRange.new(
        start: export_record.ExportStartDate.to_date,
        end: export_record.ExportEndDate.to_date,
      )
    end

    private def export_record
      @export_record ||= importable_files['Export.csv'].find_by(importer_log_id: importer_log.id)
    end

    # If we exported this from HMIS more recently than previous data (compared at day granularity)
    # then we can assume this data is more-correct even if the HMIS bungled the DateUpdated columns
    private def most_recent_export_for_ds?
      return false if export_record.ExportDate.blank?
      return true if export_record.class.where(data_source_id: export_record.data_source_id).count <= 1

      previous_date = export_record.class.
        where(data_source_id: export_record.data_source_id).
        where.not(id: export_record.id).
        maximum(:ExportDate).to_date
      export_record.ExportDate.to_date >= previous_date
    end

    def pause_import
      Rails.logger.info "pause_import #{hash_as_log_str({ importer_log_id: importer_log.id })}"

      @import_log&.update(importer_log: importer_log)
      importer_log.update(status: :paused)
    end

    def summary_for(file, type)
      importer_log.summary[file][type]
    end

    def note_processed(file, increment_by, type)
      return if increment_by.nil? || increment_by.zero?

      importer_log.summary[file][type] ||= 0
      importer_log.summary[file][type] += increment_by
    end

    ##
    # Resets the import counts for each importable file.
    #
    # This method ensures that the counts for 'added' and 'removed' records
    # are set to zero before running ingest!.
    # These numbers are pre-calculated and saved to determine if the import should trigger any
    # notifications or should pause.  They are re-added as we process batches of data and
    # delete existing records, so we'll zero them out and let the re-accumulate
    #
    # @return [void]
    #
    private def reset_import_counts
      importable_files.each_key do |file|
        ['added', 'removed'].each do |type|
          importer_log.summary[file][type] = 0
        end
      end
    end

    def setup_summary(file)
      importer_log.summary ||= {}
      importer_log.summary[file] ||= {
        'pre_processed' => 0,
        'added' => 0,
        'updated' => 0,
        'unchanged' => 0,
        'removed' => 0,
        'total_errors' => 0,
      }
    end

    # Note, only used for tests
    def self.soft_deletable_sources(version)
      importable_files_map(version).except('Export.csv').values.map { |name| "GrdaWarehouse::Hud::#{name}".safe_constantize }.compact
    end

    def setup_import
      return importer_log if importer_log.present?

      @importer_log = HmisCsvImporter::Importer::ImporterLog.create!(
        data_source: data_source,
        summary: {},
      )
    end

    def start_import
      db_transaction do
        importer_log.update(status: :started, started_at: Time.current)
        @loader_log.update(importer_log_id: importer_log.id)
        @started_at = Time.current
        log("Starting import for #{hash_as_log_str log_ids}.")
      end
    end

    def complete_import
      db_transaction do
        importer_log.status = :complete
        importer_log.completed_at = Time.current
        importer_log.upload_id = @upload.id if @upload.present?
        importer_log.save!
        data_source.update!(last_imported_at: Time.current)
        elapsed = importer_log.completed_at - @started_at
        Rails.logger.tagged({ task_name: 'HMIS CSV Importer', repeating_task: true, task_runtime: elapsed }) do
          log("Completed importing in #{elapsed_time(elapsed)} #{hash_as_log_str log_ids}.  #{summary_as_log_str(importer_log.summary)}")
        end
        @import_log&.update!(importer_log: importer_log)
      end
    end

    private def post_process
      log_timing :project_cleanup
      log_timing :cleanup_dangling_enrollments
      log_timing :identify_duplicates
      log_timing :queue_enrollment_processing
      log_timing :maintain_ch_enrollments
      log_timing :check_csv_monitors
    end

    private def check_csv_monitors
      GrdaWarehouse::Monitoring::Tasks::CsvImportMonitorCollector.run!(
        data_source: @data_source,
        importer_log: importer_log,
        import_log: @import_log,
      )
    end

    private def project_cleanup
      project_ids = GrdaWarehouse::Hud::Project.
        where(data_source_id: @data_source.id, ProjectID: involved_project_ids).
        pluck(:id)
      GrdaWarehouse::Tasks::ProjectCleanup.new(project_ids: project_ids.uniq).run! if @project_cleanup
    end

    private def cleanup_dangling_enrollments
      return if @updated_source_client_ids.empty?

      @updated_source_client_ids.each_slice(SELECT_BATCH_SIZE) do |personal_id_batch|
        updated_client_ids = GrdaWarehouse::Hud::Client.
          joins(:warehouse_client_source).
          where(PersonalID: personal_id_batch, data_source_id: @data_source.id).
          pluck(wc_t[:destination_id])
        GrdaWarehouse::Tasks::ServiceHistory::Enrollment.ensure_there_are_no_extra_enrollments_in_service_history(updated_client_ids)
      end
    end

    private def queue_enrollment_processing
      # Enrollment.processed_as is cleared if the enrollment changed
      # queue up a rebuild to keep things as in sync as possible
      GrdaWarehouse::Tasks::ServiceHistory::Enrollment.queue_batch_process_unprocessed!
    end

    private def maintain_ch_enrollments
      # These need to be updated any time the enrollment changes
      GrdaWarehouse::ChEnrollment.maintain!
    end

    private def identify_duplicates
      GrdaWarehouse::Tasks::IdentifyDuplicates.new.run!
    end

    private def db_transaction(&block)
      GrdaWarehouse::Hud::Base.transaction(&block)
    end

    def add_error(file:, klass:, source_id:, message:)
      note_processed(file, 1, 'total_errors')
      log(message)
      importer_log.import_errors.build(
        source_type: klass,
        source_id: source_id,
        message: "Error importing #{klass}",
        details: message,
      )
    end

    # A helper to determine if the class is simply augmenting an existing warehouse class
    # These classes add data to a subset of columns to an existing warehouse class
    private def custom_augmentation?(klass)
      klass.respond_to?(:augments?) && klass.augments?
    end

    # A helper to determine if the class is a custom file
    # These classes need to preload mapping data before processing
    private def custom_file?(klass)
      klass.respond_to?(:custom_file?) && klass.custom_file?
    end

    private def total_files
      @total_files ||= importable_files.count
    end
  end
end
