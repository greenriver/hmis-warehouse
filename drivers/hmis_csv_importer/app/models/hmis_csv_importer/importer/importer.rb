###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Assumptions:
# The import is authoritative for the date range specified in the Export.csv file
# The import is authoritative for the projects specified in the Project.csv file
# There's no reason to have client records with no enrollments
# All tables that hang off a client also hang off enrollments

# reload!; importer = HmisCsvImporter::Importer::Importer.new(loader_id: 2, data_source_id: 14, debug: true); importer.import!

# Some notes on how to manually run imports where the delayed job expires or fails for non-data related issue
# il = GrdaWarehouse::ImportLog.last
# loader = HmisCsvImporter::Loader::LoaderLog.last
# imp_log = HmisCsvImporter::Importer::ImporterLog.last
# # NOTE: newing up an importer currently creates an ImporterLog, this should be deleted
# imp = HmisCsvImporter::Importer::Importer.new(loader_id: loader.id, data_source_id: loader.data_source_id)
# imp.importer_log = imp_log
# il.update(import_errors: nil)
# # at this point, you can call any of the various import methods, usually, the last one that was attempted
# imp.log_timing(:process_existing)

require 'memery'
require 'zlib'
require 'base64'

module HmisCsvImporter::Importer
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
      project_cleanup: true
    )
      setup_notifier('HMIS CSV Importer')
      @loader_log = HmisCsvImporter::Loader::LoaderLog.find(loader_id.to_i)
      @data_source = GrdaWarehouse::DataSource.find(data_source_id.to_i)
      @debug = debug # no longer used for anything. instead we use logger.levels.
      @updated_source_client_ids = []

      @deidentified = deidentified
      @project_cleanup = project_cleanup
      self.importer_log = setup_import
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

      ingest!
      log_timing :invalidate_aggregated_enrollments!
      complete_import
      log_timing :post_process
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
      log_timing :post_process
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
      file_lookup = self.class.importable_files_map.invert

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
      # This makes an estimate of the changes that will occur as it needs to be done before the
      # actual processing so that it can pause the import if necessary.
      # NOTE: as written this causes 2 additional, potentially slow queries
      importable_files.map do |file, klass|
        incoming_data = klass.incoming_data(importer_log_id: importer_log.id).
          pluck(klass.hud_key).to_set

        to_add = (incoming_data - existing_hud_keys(klass)).count
        # If we never delete, just pretend it will be 0
        to_remove = 0 if klass.prevent_import_deletions?
        to_remove ||= (existing_hud_keys(klass) - incoming_data).count

        importer_log.summary[file]['added'] = to_add
        importer_log.summary[file]['removed'] = to_remove
      end
    end

    ##
    # Retrieves the set of existing HUD keys from the warehouse for a given class.
    #
    # This method queries the warehouse for records that match the data source,
    # involved projects, and date range. It then extracts and returns the HUD keys
    # as a set for efficient lookup and comparison.
    #
    # @param klass [Class] The class representing the data model being queried.
    # @return [Set<String>] A set of existing HUD keys for the given class.
    #
    memoize private def existing_hud_keys(klass)
      klass.existing_data(
        data_source_id: data_source.id,
        project_ids: involved_project_ids,
        date_range: date_range,
      ).pluck(klass.hud_key).to_set
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
        klass = importable_files[file]
        to_add = data['added']
        to_remove = data['removed']
        [
          file,
          {
            change_count: (to_add - to_remove).abs,
            total_count: existing_hud_keys(klass).count,
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
      bm = Benchmark.measure do
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

          # FIXME: are we sure this source_hash algo matches
          # existing import logic. If not all records will be considered modified on the next run
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
        pp_secs: bm.real.round(3),
        pp_rps: ((records / bm.real).round(3) unless records.zero?),
        pp_cpu: "#{(bm.total * 100.0 / bm.real).round}%",
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
          aggregator_klass.new(importer_log: @importer_log, date_range: date_range).rebuild_warehouse_data
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
      importable_files.each_value do |klass|
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

    def add_new_data
      importable_files.each do |file_name, klass|
        destination_class = klass.reflect_on_association(:destination_record).klass
        # Rails.logger.debug "Adding #{destination_class.table_name} #{hash_as_log_str log_ids}"
        batch = []
        # This is the same query as `existing_hud_keys` but the memoization of that method prevents this from
        # using it.
        existing_keys = nil
        with_sql_log(__method__, klass, name: 'existing_data') do
          existing_keys = klass.existing_data(
            data_source_id: data_source.id,
            project_ids: involved_project_ids,
            date_range: date_range,
          ).pluck(klass.hud_key).to_set
        end

        bm = Benchmark.measure do
          klass.incoming_data(importer_log_id: importer_log.id).find_each(batch_size: SELECT_BATCH_SIZE) do |row|
            next if existing_keys.include?(row[klass.hud_key])

            batch << row.as_destination_record
            if batch.count == INSERT_BATCH_SIZE
              # NOTE: we are allowing upserts to handle the situation where data is in the warehouse with a HUD key that
              # for whatever reason doesn't fall within the involved scope
              # also NOTE: if aggregation is used, the count of added Enrollments and Exits will reflect the
              # entire history of enrollments for aggregated projects because some of the existing enrollments fall
              # outside of the range, but are necessary to calculate the correctly aggregated set
              upsert = ! destination_class.name.in?(un_updateable_warehouse_classes)
              columns = batch.first.attributes.keys - ['id']
              process_batch!(destination_class, batch, file_name, columns: columns, type: 'added', upsert: upsert)
              batch = []
            end
          end
          # NOTE: we are allowing upserts to handle the situation where data is in the warehouse with a HUD key that
          # for whatever reason doesn't fall within the involved scope
          # also NOTE: if aggregation is used, the count of added Enrollments and Exits will reflect the
          # entire history of enrollments for aggregated projects because some of the existing enrollments fall
          # outside of the range, but are necessary to calculate the correctly aggregated set
          if batch.present?
            upsert = ! destination_class.name.in?(un_updateable_warehouse_classes)
            columns = batch.first.attributes.keys - ['id']
            process_batch!(destination_class, batch, file_name, columns: columns, type: 'added', upsert: upsert) # ensure we get the last batch
          end
        end
        records = summary_for(file_name, 'added') || 0
        stats = {
          add_secs: bm.real.round(3),
          add_rps: ((records / bm.real).round(3) unless records.zero?),
          add_cpu: "#{(bm.total * 100.0 / bm.real).round}%",
        }
        importer_log.summary[file_name].merge!(stats)
        Rails.logger.debug do
          "  Added #{destination_class.table_name} #{hash_as_log_str({ added: records }.merge(stats).merge(log_ids))}"
        end
      end
    end

    def un_updateable_warehouse_classes
      [
        'GrdaWarehouse::Hud::Export',
        'GrdaWarehouse::Hud::Client',
      ]
    end

    def process_existing
      # TODO: This could be parallelized
      importable_files.each do |file_name, klass|
        with_sql_log(__method__, klass) do
          mark_unchanged(klass, file_name)
          mark_incoming_older(klass, file_name)
          apply_updates(klass, file_name)
        end
      end
    end

    def remove_pending_deletes
      importable_files.each do |file_name, klass|
        # Never delete Exports
        next if klass.hud_key == :ExportID

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
          # Do this in batches to avoid the complex join during the update
          scope = existing_destination_data_scope(klass)
          all_ids = nil
          with_sql_log(__method__, klass, name: 'existing_destination_data_scope') do
            all_ids = scope.pluck(:id)
          end
          update_scope = if scope.klass.paranoid?
            scope.klass.with_deleted
          else
            scope.klass
          end
          all_ids.each_slice(INSERT_BATCH_SIZE) do |ids|
            update_scope.where(id: ids).update_all(pending_date_deleted: nil, DateDeleted: Time.current, source_hash: nil)
          end
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

      destination_class = klass.reflect_on_association(:destination_record).klass
      # Rails.logger.debug "Updating #{destination_class.name} #{hash_as_log_str log_ids}"

      # existing = existing_destination_data_scope(klass).distinct.pluck(klass.hud_key)
      bm = Benchmark.measure do
        batch = []
        # existing.each_slice(SELECT_BATCH_SIZE) do |hud_keys|
        existing_destination_data_scope(klass).in_batches(of: SELECT_BATCH_SIZE) do |relation|
          hud_keys = relation.pluck(klass.hud_key)
          klass.should_import.where(
            importer_log_id: @importer_log.id,
            klass.hud_key => hud_keys,
          ).find_each(batch_size: SELECT_BATCH_SIZE) do |source|
            destination = source.as_destination_record
            destination.pending_date_deleted = nil
            case klass.hud_key
            when :PersonalID
              destination.demographic_dirty = true
            when :EnrollmentID
              destination.processed_as = nil
            when :ExitID
              # These are tracked separately so we can bulk update them at the end
              track_dirty_enrollment(destination.EnrollmentID)
            end
            batch << destination
            if batch.count == INSERT_BATCH_SIZE
              # Client model doesn't have a uniqueness constraint because of the warehouse data source
              # so these must be processed more slowly
              if klass.hud_key == :PersonalID
                batch.each do |incoming|
                  destination_class.where(
                    data_source_id: incoming.data_source_id,
                    PersonalID: incoming.PersonalID,
                  ).with_deleted.update_all(incoming.slice(klass.upsert_column_names))
                  @updated_source_client_ids << incoming.PersonalID
                end
                note_processed(file_name, batch.count, 'updated')
              else
                process_batch!(destination_class, batch, file_name, type: 'updated', upsert: true)
              end
              batch = []
            end
          end
        end
        if batch.present? # ensure we get the last batch
          if klass.hud_key == :PersonalID
            batch.each do |incoming|
              destination_class.where(
                data_source_id: incoming.data_source_id,
                PersonalID: incoming.PersonalID,
              ).with_deleted.update_all(incoming.slice(klass.upsert_column_names))
              @updated_source_client_ids << incoming.id
            end
            note_processed(file_name, batch.count, 'updated')
          else
            process_batch!(destination_class, batch, file_name, type: 'updated', upsert: true)
          end
        end

        # If we tracked any dirty enrollments, we can mark them all dirty now
        if klass.hud_key == :ExitID
          GrdaWarehouse::Hud::Enrollment.where(data_source_id: data_source.id, EnrollmentID: dirty_enrollment_ids).
            update_all(processed_as: nil)
        end
      end
      records = summary_for(file_name, 'updated') || 0
      stats = {
        up_secs: bm.real.round(3),
        up_rps: ((records / bm.real).round(3) unless records.zero?),
        up_cpu: "#{(bm.total * 100.0 / bm.real).round}%",
      }
      importer_log.summary[file_name].merge!(stats)
      Rails.logger.debug do
        "  Updated #{destination_class.table_name} #{hash_as_log_str({ updated: records }.merge(stats).merge(log_ids))}"
      end
    end

    # Compare source_hash new and old, if they are identical, we don't need to do anything
    private def mark_unchanged(klass, file_name)
      # We always bring over Exports
      return if klass.hud_key == :ExportID

      existing = existing_destination_data_scope(klass).where.not(DateUpdated: nil). # A bad import can sometimes cause this
        pluck(klass.hud_key, :source_hash)
      incoming = klass.should_import.where(importer_log_id: @importer_log.id).
        pluck(klass.hud_key, :source_hash)
      unchanged = (existing & incoming).map(&:first)
      unchanged.each_slice(INSERT_BATCH_SIZE) do |batch|
        query = klass.warehouse_class.where(
          data_source_id: data_source.id,
          klass.hud_key => batch,
        )
        query = query.with_deleted if klass.warehouse_class.paranoid?
        query.update_all(pending_date_deleted: nil)
        note_processed(file_name, batch.count, 'unchanged')
      end
    end

    # Having already excluded unchanged records, compare DateUpdated,
    # if the incoming record is older than the existing record,
    # don't update the warehouse.
    # NOTE: there is one exception, if the import is the most recently
    # exported for this data source, then we should assume the data is
    # more correct than anything we have
    private def mark_incoming_older(klass, file_name)
      # Doesn't apply to Exports
      return if klass.hud_key == :ExportID
      return if most_recent_export_for_ds?

      existing = existing_destination_data_scope(klass).pluck(klass.hud_key, :DateUpdated).to_h
      incoming = klass.should_import.where(importer_log_id: @importer_log.id).
        pluck(klass.hud_key, :DateUpdated).to_h

      # ignore any where we don't have a DateUpdated,
      # or we don't have a matching incoming record
      existing.reject! { |k, v| v.blank? || incoming[k].blank? }

      # if the incoming DateUpdated is strictly less than the existing one
      # trust the warehouse is correct
      unchanged = existing.select { |k, v| incoming[k].to_date < v.to_date }.keys
      unchanged.each_slice(INSERT_BATCH_SIZE) do |batch|
        query = klass.warehouse_class.where(
          data_source_id: data_source.id,
          klass.hud_key => batch,
        )
        query = query.with_deleted if klass.warehouse_class.paranoid?
        query.update_all(pending_date_deleted: nil)
        note_processed(file_name, batch.count, 'unchanged')
      end
    end

    private def track_dirty_enrollment(enrollment_id)
      @track_dirty_enrollment ||= Set.new
      @track_dirty_enrollment << enrollment_id
    end

    private def dirty_enrollment_ids
      @track_dirty_enrollment
    end

    private def process_batch!(klass, batch, file_name, type:, upsert:, columns: klass.upsert_column_names)
      Rails.logger.debug { "process_batch! #{klass} #{upsert ? 'upsert' : 'import'} #{batch.size} records" }
      klass.logger.silence(Logger::WARN) do
        if upsert
          klass.import(
            batch,
            on_duplicate_key_update: {
              conflict_target: klass.conflict_target,
              columns: columns,
            },
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
        if upsert
          klass.import(
            Array.wrap(row),
            on_duplicate_key_update: {
              conflict_target: klass.conflict_target,
              columns: columns,
            },
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

    private def source_data_scope_for(file_name)
      scope = HmisCsvImporter::Loader::Loader.loadable_files[file_name]
      scope.unscoped.where(loader_id: @loader_log.id)
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

    def importable_files
      self.class.importable_files
    end

    def importable_file_class(name)
      self.class.data_lake_file_class(name, 'Importer')
    end

    def self.soft_deletable_sources
      importable_files_map.except('Export.csv').values.map { |name| "GrdaWarehouse::Hud::#{name}".constantize }
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
      # s_time = Time.current
      project_ids = GrdaWarehouse::Hud::Project.
        where(data_source_id: @data_source.id, ProjectID: involved_project_ids).
        pluck(:id)
      GrdaWarehouse::Tasks::ProjectCleanup.new(project_ids: project_ids.uniq).run! if @project_cleanup

      # Clean up any dangling enrollments for updated clients
      updated_client_ids = GrdaWarehouse::Hud::Client.
        joins(:warehouse_client_source).
        where(PersonalID: @updated_source_client_ids, data_source_id: @data_source.id).
        pluck(wc_t[:destination_id])
      GrdaWarehouse::Tasks::ServiceHistory::Enrollment.ensure_there_are_no_extra_enrollments_in_service_history(updated_client_ids)

      # Enrollment.processed_as is cleared if the enrollment changed
      # queue up a rebuild to keep things as in sync as possible
      GrdaWarehouse::Tasks::IdentifyDuplicates.new.run!
      GrdaWarehouse::Tasks::ServiceHistory::Enrollment.queue_batch_process_unprocessed!
      # These need to be updated any time the enrollment changes
      GrdaWarehouse::ChEnrollment.maintain!
      # puts "Took #{Time.current - s_time} seconds - #{Time.current}"
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
  end
end
